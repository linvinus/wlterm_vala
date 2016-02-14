using Posix;

//~ [CCode (cname = "execve")]
//~ extern int execve(string path, string[] arg, string[] environ);


class terminal_renderer {
  HashTable<string, int> glyphs;
}

class term_t {
  Tsm.Screen screen;
  Tsm.Vte vte;
  Shlpty.Bridge pty_bridge;
  IOChannel bridge_chan;
  uint bridge_src;
  GLib.Source pty_idle;
  Shlpty.Shlpty pty;
  uint child_src;
  uint pty_idle_src=0;

  Pango.FontDescription font_desc;
  Gtk.Window win;
  Gtk.DrawingArea tarea;

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

  public void my_write_cb(Tsm.Vte vte,
				  char* u8,
				  size_t len){
  int r;
  
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

    r = this.pty_bridge.dispatch(0);
    if (r < 0)
      print("bridge dispatch failed (%d)", r);
    return true;
  }

  public void term_read_cb(Shlpty.Shlpty shelpty, char *u8,size_t len){
//~     printf("new char:%s\n",(string)u8);
    this.vte.input((uchar[])u8, len);
    this.tarea.queue_draw();
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

  
  int screen_draw_cb (Tsm.Screen screen,
				   uint32 id,
				   uint32 ch,
				   size_t len,
				   uint width,
				   uint posx,
				   uint posy,
				   Tsm.screen_attr attr,
				   Tsm.Tsmage age ){
             
//~         const struct wlt_draw_ctx *ctx = data;
//~         struct wlt_renderer *rend = ctx->rend;
//~         uint8 fr, fg, fb, br, bg, bb;
//~         uint x, y;
//~         struct wlt_glyph *glyph;
//~         bool skip;
//~         int r;

//~         x = posx * ctx->cell_width;
//~         y = posy * ctx->cell_height;

        /* If the cell is inside of the dirty-region *and* our age and the
         * cell age is non-zero *and* the cell-age is smaller than our age,
         * then skip drawing as it's already on-screen. */
//~         skip = overlap(ctx, x, y, x + ctx->cell_width, y + ctx->cell_height);
//~         skip = skip && age && rend->age && age <= rend->age;

//~         if (skip && !ctx->debug)
//~           return 0;

        /* invert colors if requested */
//~         if (attr->inverse) {
//~           fr = attr->br;
//~           fg = attr->bg;
//~           fb = attr->bb;
//~           br = attr->fr;
//~           bg = attr->fg;
//~           bb = attr->fb;
//~         } else {
//~           fr = attr->fr;
//~           fg = attr->fg;
//~           fb = attr->fb;
//~           br = attr->br;
//~           bg = attr->bg;
//~           bb = attr->bb;
//~         }

        /* !len means background-only */
//~         if (!len) {
//~           wlt_renderer_fill(rend, x, y, ctx->cell_width * cwidth,
//~                 ctx->cell_height, br, bg, bb);
//~         } else {
//~           r = wlt_face_render(ctx->face, &glyph, id, ch, len, cwidth);
//~           if (r < 0)
//~             wlt_renderer_fill(rend, x, y, ctx->cell_width * cwidth,
//~                   ctx->cell_height, br, bg, bb);
//~           else
//~             wlt_renderer_blend(rend, glyph, x, y,
//~                    fr, fg, fb, br, bg, bb);
//~         }

//~         if (!skip && ctx->debug)
//~           wlt_renderer_highlight(rend, x, y, ctx->cell_width * cwidth,
//~                      ctx->cell_height);

        return 0;
    }//screen_draw_cb

  bool term_draw_cb (Cairo.Context cr){
      var pagenum_layout = Pango.cairo_create_layout(cr);
      pagenum_layout.set_font_description(this.font_desc);
      pagenum_layout.set_height(0);
      pagenum_layout.set_spacing(0);

      print("term_draw_cb\n");
//~     	Tsm.Tsmage age = this.screen.draw(screen_draw_cb);
    	Tsm.Tsmage age = this.screen.draw((screen,
				   id,
				   ch,
				   len,
				   width,
				   posx,
				   posy,
				   attr,
				   age )=>{
             char * val;
             size_t ulen=0;
//~              print("this.screen.draw [%s] len=%d width=%d posx=%d posx=%d\n",(string)ch,(int)len,(int)width,(int)posx,(int)posy);
//~              cr.move_to(posx*10, posy*20);

            //background
            cr.set_source_rgb(
                     attr.br / 255.0,
                     attr.bg / 255.0,
                     attr.bb / 255.0);
            
            cr.rectangle(posx*this.cell_width, posy*this.cell_height, this.cell_width, this.cell_height);
            cr.fill();
            
            //text
            cr.move_to(posx*this.cell_width, posy*this.cell_height);
            cr.set_source_rgb(
                     attr.fr / 255.0,
                     attr.fg / 255.0,
                     attr.fb / 255.0);

              if(ch=="")ch=" ";
                val = Tsm.ucs4_to_utf8_alloc(ch, len, out ulen);

              pagenum_layout.set_text((string)val, (int)ulen);
                     
              Pango.cairo_show_layout(cr, pagenum_layout);
        return 0;
        });
    return false;
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

        this.initialized=true;
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
  public term_t(){

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

      this.pty_idle = new GLib.IdleSource();

      this.start_terminal();

      this.font_desc = new Pango.FontDescription();
      this.font_desc.set_family("Mono");
      this.font_desc.set_size((int)(9 * Pango.SCALE));

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

      this.win = new Gtk.Window ();
      this.win.destroy.connect(Gtk.main_quit);
      this.tarea = new Gtk.DrawingArea ();
      this.tarea.configure_event.connect(this.term_configure_cb);
      this.tarea.draw.connect(this.term_draw_cb);
      this.win.add(this.tarea);

      this.win.key_press_event.connect((e)=>{
          uint32 ucs4;
          uint mods = 0;

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

          if (this.vte.handle_keyboard(e.keyval, 0, mods, ucs4)) {
            this.screen.sb_reset();
            return true;
          }
          
          return false;
        });
      
      this.win.show_all();
  }//constructor

  void term_recalc_cells()
  {
    this.columns = this.width / this.cell_width;
    this.rows = this.height / this.cell_height;

    if (this.columns == 0)
      this.columns = 1;
    if (this.rows == 0)
      this.rows = 1;
  }
}

int main (string[] argv) {
  Gtk.init(ref argv);
  term_t term = new term_t();
  Gtk.main();
//~   GLib.stdin.read_line ();
return 0;
}
