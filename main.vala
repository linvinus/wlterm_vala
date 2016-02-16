using Posix;

//~ [CCode (cname = "execve")]
//~ extern int execve(string path, string[] arg, string[] environ);


class Term_dbus_client {
  Gtk.Window win;
  Gtk.DrawingArea tarea;
//~   Gtk.EventBox tarea;

  public Term_dbus_client() {
      int shmid;
      char *data;
      /* connect to (and possibly create) the segment: */
      if ((shmid = Shm.get(888222, 64, 0644 | IPC.CREAT)) == -1) {
          printf("shmget");
          exit(1);
      }
      shmctl(shmid, IPC_RMID, NULL);
      /* attach to the segment to get a pointer to it: */
      data = Shm.at(shmid, (void *)0, 0);
      if (data == (char *)(-1)) {
          printf("shmat");
          exit(1);
      }

    /* detach from the segment: */
    if (Shm.dt(data) == -1) {
        printf("shmdt");
        exit(1);
    }

      this.tarea = new Gtk.DrawingArea ();
      this.tarea.set_has_window (false);
      this.tarea.set_app_paintable(true);
      this.tarea.set_double_buffered(false);
//~       this.tarea.set_reallocate_redraws(false);

//~       this.tarea.draw.connect(this.term_draw_cb);

      this.win = new Gtk.Window ();
      this.win.set_app_paintable(true);
      this.win.set_double_buffered(false);
      this.win.destroy.connect(Gtk.main_quit);

//~       this.win.configure_event.connect(this.term_configure_cb);

      this.win.set_reallocate_redraws(false);
      this.win.add(this.tarea);

      this.win.key_press_event.connect((e)=>{
          uint32 ucs4;
          uint mods = 0;
          debug("key_press_event");

          if ( (e.state & Gdk.ModifierType.SHIFT_MASK) == Gdk.ModifierType.SHIFT_MASK)
            mods |= Tsm.Vte_modifier.SHIFT_MASK;
          if ( (e.state & Gdk.ModifierType.LOCK_MASK) == Gdk.ModifierType.LOCK_MASK)
            mods |= Tsm.Vte_modifier.LOCK_MASK;
          if ( (e.state & Gdk.ModifierType.CONTROL_MASK) == Gdk.ModifierType.CONTROL_MASK)
            mods |= Tsm.Vte_modifier.CONTROL_MASK;
          if ( (e.state & Gdk.ModifierType.MOD1_MASK) == Gdk.ModifierType.MOD1_MASK)
            mods |= Tsm.Vte_modifier.ALT_MASK;
          if ( (e.state & Gdk.ModifierType.MOD4_MASK) == Gdk.ModifierType.MOD4_MASK)
            mods |= Tsm.Vte_modifier.LOGO_MASK;

          ucs4 = xkb_keysym_to_utf32(e.keyval);
          if (ucs4 == 0)
            ucs4 = Tsm.TSM_VTE_INVALID;

//~           if (this.vte.handle_keyboard(e.keyval, 0, mods, ucs4)) {
//~             this.screen.sb_reset();
//~             return true;
//~           }

          return false;
        });

      this.win.show_all();

  }//constructor Term_dbus_client

}//class Term_dbus_client

//~ [DBus (name = "org.example.Demo")]

class Term_dbus_server {
  Tsm.Screen screen;
  Tsm.Vte vte;
  Shlpty.Bridge pty_bridge;
  IOChannel bridge_chan;
  uint bridge_src;
//~   GLib.Source pty_idle;
  Shlpty.Shlpty pty;
  uint child_src;
  uint pty_idle_src=0;
  Tsm.Tsmage prev_age=0;

  Pango.FontDescription font_desc;

  Cairo.ImageSurface terminal_db_image;
	Cairo.Context terminal_db_cr;
  Pango.Layout font_layout;
  bool force_redraw=false;//force redraw after resize

	uint cell_width;
	uint cell_height;
	uint width;
	uint height;
	uint columns;
	uint rows;
  bool initialized=false;


  void mylog(
           string file,
           int line,
           string func,
           string subs,
           uint sev,
           string format,
           va_list args){
    GLib.stderr.printf("%s: %s: ", sev.to_string(), subs);
    GLib.stderr.printf(format, args);
    GLib.stderr.printf( "\n");
  }

  /*stdin мы пишем в терминал с клавиатуры, потом дёргаем term_bridge_cb*/
  public void my_write_cb(Tsm.Vte vte,
				  char* u8,
				  size_t len){
  int r;
  debug("my_write_cb (%d) \"%s\"",(int)len,((string)u8).substring(0,(long)len));
	r = this.pty.write(u8, len);
	if (r < 0)
		printf("OOM in pty-write (%d)", r);

	if ( this.pty_idle_src == 0 )
		this.pty_idle_src = GLib.Idle.add(()=>{
        this.pty.dispatch();
        this.pty_idle_src=0;
        return false;//stop
      });

  }

  bool term_bridge_cb (IOChannel source, IOCondition condition) {
    int r;
    debug("term_bridge_cb");
    r = this.pty_bridge.dispatch(0);
    if (r < 0)
      print("bridge dispatch failed (%d)", r);
    return true;
  }

  /*stdout терминал нам пишет, сначала об этом узнаёт term_bridge_cb*/
  public void term_read_cb(Shlpty.Shlpty shelpty, char *u8,size_t len){
//~     printf("new char:%s\n",(string)u8);
    this.vte.input(u8, len);

    debug("!!!!this.tarea.queue_draw();");

    debug("term_read_cb (%d) \"%s\"",(int)len,((string)u8).substring(0,(long)len));
  }

  void term_notify_resize()
  {
    int r;

    r = this.screen.resize(this.columns, this.rows);
    if (r < 0)
      printf("cannot resize TSM screen (%d)", r);

    r = this.pty.resize((ushort)this.columns, (ushort)this.rows);
    if (r < 0)
      printf("cannot resize pty (%d)", r);
  }


  bool term_draw_cb (Gtk.Widget    widget,Cairo.Context cr2){
      debug("term_draw_cb");
      int64 start, end;
      if(!this.initialized) return false;
      start=GLib.get_monotonic_time();

//https://developer.gnome.org/gtk3/stable/chap-drawing-model.html#double-buffering

//~       this. begin_paint_region
//~       this.terminal_db_image.flush();
      this.terminal_db_cr.save();



//~        terminal_db_cr.move_to(0, 0);
      double x1,x2,y1,y2;
      cr2.clip_extents( out x1, out y1, out x2, out y2);
//~       var clip_rectangle = Cairo.Region.rectangle();

//~       Gdk.Rectangle grect={(int)x1,(int)y1,(int)(x2-x1),(int)(y2-y1)};
//~       widget.get_window ().begin_paint_rect(grect);

//~       terminal_db_cr.rectangle(x1, y1, x2, y2);
//~       terminal_db_cr.fill();
//~       this.terminal_db_cr.restore();
//~       terminal_db_cr.move_to(x1, y1);
//~       this.terminal_db_cr.save();
      //background
//~       cr2.move_to(GLib.Random.int_range(0,50),GLib.Random.int_range(0,50));
//~       cr2.set_source_rgb(1.0,0,0);
//~       cr2.select_font_face ( "Mono",
//~           Cairo.FontSlant.NORMAL, Cairo.FontWeight.BOLD);
//~       cr2.set_font_size ( 20.2);
//~       cr2.show_text("denis");

//~       cr2.line_to(x2, y2);
//~       cr2.stroke();
//~       cr2.rectangle(x1, y1, x2, y2);
//~       cr2.fill();


      x1 /= this.cell_width;
      x2 /= this.cell_width;
      y1 /= this.cell_height;
      y2 /= this.cell_height;
      x1=(int)x1; x2+=0.5; x2=(int)x2;
      y1=(int)y1; y2+=0.5; y2=(int)y2;

//~       print("term_draw_cb l=%f t=%f r=%f b=%f prev_age=%d\n",x1,y1,x2,y2,(int)this.prev_age);
//~     	Tsm.Tsmage age = this.screen.draw(screen_draw_cb);
    	this.prev_age = this.screen.draw((screen,
				   id,
				   ch,
				   len,
				   width,
				   posx,
				   posy,
				   attr,
				   age )=>{

            if(!this.force_redraw ){ //&& attr.blink != 0 && attr.protect != 0
               if( !( ((x1 <= posx)&&(posx<= x2)) && ((y1 <= posy) && (posy <= y2)) )  )
                return 0;//skip dwaw if not in damaged region

//~                 printf("=%d,%d age=%d prev_age=%d\n",(int)posx,(int)posy,(int)age, (int)prev_age);

               if(this.prev_age>0 &&  age < this.prev_age){
                return 0;//skip draw if not enough old
                }

            }

            uint8 fr, fg, fb, br, bg, bb;
            // invert colors if requested
            if (attr.inverse == 1) {
              fr = attr.br;
              fg = attr.bg;
              fb = attr.bb;
              br = attr.fr;
              bg = attr.fg;
              bb = attr.fb;
            } else {
              fr = attr.fr;
              fg = attr.fg;
              fb = attr.fb;
              br = attr.br;
              bg = attr.bg;
              bb = attr.bb;
            }



//~              print("this.screen.draw [%s] len=%d width=%d posx=%d posx=%d\n",(string)ch,(int)len,(int)width,(int)posx,(int)posy);
//~              cr.move_to(posx*10, posy*20);

            //background
            this.terminal_db_cr.set_source_rgb(
                     br / 255.0,
                     bg / 255.0,
                     bb / 255.0);

            this.terminal_db_cr.rectangle(posx*this.cell_width, posy*this.cell_height, this.cell_width, this.cell_height);
            this.terminal_db_cr.fill();

            if(len>0){
              //text
              this.terminal_db_cr.save();
              if(ch=="")ch=" ";

              size_t ulen=0;
              string  cval = Tsm.ucs4_to_utf8_alloc(ch, len, out ulen);
              var val=cval.substring(0,(long)ulen);

//~               this.terminal_db_cr.select_font_face ( "Monospace",
//~                   Cairo.FontSlant.NORMAL, Cairo.FontWeight.NORMAL);
//~                   Cairo.FontSlant.NORMAL, Cairo.FontWeight.BOLD);
//~               this.terminal_db_cr.set_font_size ( (14 ));



//~               Cairo.TextExtents extents;
//~               this.terminal_db_cr.text_extents (val, out extents);
//~               var x =(posx*this.cell_width)+(this.cell_width/2)-(extents.width/2 + extents.x_bearing);
//~               var y = (posy*this.cell_height)+(this.cell_height/2) - (extents.height/2 + extents.y_bearing);
//~               this.terminal_db_cr.move_to(x, y);
//~               this.terminal_db_cr.move_to((posx*this.cell_width), (posy*this.cell_height)+(this.cell_height/2) - (extents.height/2 + extents.y_bearing));
              this.terminal_db_cr.move_to((posx*this.cell_width), (posy*this.cell_height));
              this.terminal_db_cr.set_source_rgb(
                       fr / 255.0,
                       fg / 255.0,
                       fb / 255.0);

//~                 this.terminal_db_cr.show_text(val);//(string)val

                font_layout.set_text(val, (int)ulen);
//~                 Pango.cairo_update_layout(this.terminal_db_cr,font_layout);
//~                 font_layout.add_to_cairo_context(this.terminal_db_cr);
//~                 this.terminal_db_cr.stroke();

                Pango.cairo_show_layout(this.terminal_db_cr, font_layout);
                this.terminal_db_cr.restore();
              }
        return 0;
        });

    this.prev_age++;//<=

  this.terminal_db_cr.restore();

  this.terminal_db_image.mark_dirty();
	cr2.set_source_surface(this.terminal_db_image, 0, 0);
	cr2.paint();

//~     widget.get_window ().end_paint();//notify for single buffer mode

    end = GLib.get_monotonic_time();
    if (1==0)
      print("draw: %lldms widg=%d\n", (end - start) / 1000,(int)widget);

    this.force_redraw=false;
    return true;//stop other handlers from being invoked for the event
  }

  void  term_run_child()
  {
    string[] argv = {
      GLib.Environment.get_variable("SHELL") ,
      /*"/usr/local/bin/debugaltyo.sh",*/
      "-il",
      null
      };

    GLib.Environment.set_variable("TERM", "xterm-256color", true);
//~     execve(argv[0], argv, environ);
    printf("Starting %s",argv[0]);
    Posix.execv(argv[0], argv);
    exit(1);

  }//term_run_child

  void term_child_exit_cb(Pid pid, int status)
  {
    debug("term_child_exit_cb");
    GLib.Process.close_pid(pid);
    this.child_src = 0;
    Gtk.main_quit();
  }//term_child_exit_cb

  bool start_terminal(){
      int r, pid;
      this.columns=this.rows=100;
      printf("Shlpty.Shlpty.open\n");
      GLib.stdout.flush();
      r = Shlpty.Shlpty.open(out this.pty, term_read_cb,
             (ushort)this.columns, (ushort)this.rows);

        if (r < 0) {
          printf("cannot spawn pty (%d)\n", r);
          GLib.stdout.flush();
          Gtk.main_quit();
          return true;
        } else if (r==0) {
          /* child */
          this.term_run_child();
          exit(1);
        }

        r = this.pty_bridge.add(this.pty);
        if (r < 0) {
          printf("cannot add pty to bridge (%d)\n", r);
          this.pty.close();
          Gtk.main_quit();
          return true;
        }

        pid = this.pty.get_child();
        this.child_src = GLib.ChildWatch.add(pid, term_child_exit_cb);

        this.term_notify_resize();


        return true;
  }//start_terminal

  bool term_configure_cb (Gdk.EventConfigure event){
    this.width = event.width;
    this.height = event.height;
    if(!this.initialized){
      }
    this.term_recalc_cells();
    this.term_notify_resize();
     return false;
  }

  //constructor
  public Term_dbus_server(){

	string str = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ@!\"$%&/()=?\\}][{°^~+*#'<>|-_.:,;`´ ";


      if (Tsm.Screen.Screen_new(out  this.screen, this.mylog) <0){
        printf("Unable to create screen");
        exit(1);
      }

      this.screen.set_max_sb(500);
      if( Tsm.Vte.Vte_new(out this.vte,
                  this.screen,
                  this.my_write_cb,
                  this.mylog) < 0 ){
        printf("Unable to create vte");
        exit(1);
      }

      this.pty_bridge=Shlpty.Bridge.Bridge_new();

      if (this.pty_bridge < 0) {
        printf("Unable to create pty_bridge");
    //~ 		r = term->pty_bridge;
    //~ 		goto err_vte;
        exit(1);
      }

      this.bridge_chan = new GLib.IOChannel.unix_new(this.pty_bridge);
      this.bridge_src = this.bridge_chan.add_watch( GLib.IOCondition.IN,
                this.term_bridge_cb);

//~       this.pty_idle = new GLib.IdleSource();

      this.start_terminal();

      this.font_desc = new Pango.FontDescription();
      this.font_desc.set_family("Mono");
      this.font_desc.set_size((int)(12 * Pango.SCALE));

      //virtual surface
      var surface = new Cairo.ImageSurface(Cairo.Format.RGB24, 2000, 500);
      var cr = new Cairo.Context(surface);
      var layout = Pango.cairo_create_layout(cr);
      layout.set_font_description(this.font_desc);

      layout.set_height(0);
      layout.set_spacing(0);

      layout.set_text( str, str.length);

      Pango.Rectangle rect;
      layout.get_pixel_extents( null, out rect);


      this.cell_width = (rect.width + (str.length - 1)) / str.length;
      this.cell_height = rect.height;
      printf("cell_width=%d cell_height=%d\n",(int)this.cell_width,(int)this.cell_height);

  }//constructor

  void term_recalc_cells()
  {
      this.terminal_db_image = new Cairo.ImageSurface (Cairo.Format.ARGB32, (int)this.width, (int)this.height);
      this.terminal_db_cr    = new Cairo.Context (this.terminal_db_image);

      this.font_layout = Pango.cairo_create_layout(terminal_db_cr);
      this.font_layout.set_font_description(this.font_desc);
      this.font_layout.set_height(0);
      this.font_layout.set_spacing(0);

      this.force_redraw=true;//redraw whole window


    this.columns = this.width / this.cell_width;
    this.rows = this.height / this.cell_height;

    if (this.columns == 0)
      this.columns = 1;
    if (this.rows == 0)
      this.rows = 1;

    this.initialized=true;
  }
}

static void print_handler(string? domain, LogLevelFlags flags, string message) {
		printf("domain:%s message:%s\n",domain,message);
		GLib.stdout.flush();
	    }

void run_server(){
  var term = new Term_dbus_server();
  new MainLoop ().run ();
}

void run_client(string[] argv){
  Gtk.init(ref argv);
  var term = new Term_dbus_client();
  Gtk.main();
}

int main (string[] argv) {

					Log.set_handler(null,
						LogLevelFlags.LEVEL_MASK &
						(LogLevelFlags.LEVEL_DEBUG |
						LogLevelFlags.LEVEL_MESSAGE |
						LogLevelFlags.LEVEL_WARNING |
						LogLevelFlags.LEVEL_INFO |
						LogLevelFlags.LEVEL_CRITICAL), print_handler);

foreach(var S in argv){
  debug("S=%s",S);
  if(S == "-S"){
    run_server();
  }
  if(S == "-C"){
    run_client(argv);
  }
}
//~   GLib.stdin.read_line ();
return 0;
}
