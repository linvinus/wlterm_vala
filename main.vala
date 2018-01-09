using Posix;
using Ltk;

//~ [CCode (cname = "execve")]
//~ extern int execve(string path, string[] arg, string[] environ);

//~ const Gdk.ModifierType ALL_MODS = (Gdk.ModifierType.SHIFT_MASK | Gdk.ModifierType.LOCK_MASK | Gdk.ModifierType.CONTROL_MASK |	  Gdk.ModifierType.MOD1_MASK | Gdk.ModifierType.MOD4_MASK);


class terminal_renderer {
  HashTable<string, int> glyphs;
}

class TSMterm : Ltk.Widget {
  Tsm.Screen screen;
  Tsm.Vte vte;
  Shlpty.Bridge pty_bridge;
  IOChannel bridge_chan;
  uint bridge_src;
  GLib.Source pty_idle;
  Shlpty.Shlpty pty;
  uint child_src;
  uint pty_idle_src=0;
  Tsm.Tsmage prev_age=0;
  private bool _focused = false;

//~   Pango.FontDescription font_desc;
  
//~   Gtk.DrawingArea tarea;
//~   Gtk.EventBox tarea;
//~   Cairo.ImageSurface terminal_db_image;
//~   Cairo.Context terminal_db_cr;
//~   Pango.Layout font_layout;
//~   Gdk.Keymap ?keymap=null;
  bool force_redraw=false;//force redraw after resize

	uint cell_width;
	uint cell_height;
	uint cell_bearing;
//~ 	uint width;
//~ 	uint height;
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
    GLib.stderr.vprintf(format, args);
    GLib.stderr.printf( "\n");
  }

  public void my_write_cb(Tsm.Vte vte, char* u8,  size_t len){
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

  }//my_write_cb

  bool term_bridge_cb (IOChannel source, IOCondition condition) {
    int r;

    r = this.pty_bridge.dispatch(0);
    if (r < 0)
      print("bridge dispatch failed (%d)", r);
    return true;
  }

  public void term_read_cb(Shlpty.Shlpty shelpty, char *u8,size_t len){
//~     printf("new char:%s\n",(string)u8);
    this.vte.input(u8, len);
    this.damaged = true;//redraw with new state
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

    //set input focus
    public override bool set_focus(bool focus){
      this._focused = focus;
      if(!focus && (this.state & WidgetState.focused) >0 ){
        this.state  &= ~WidgetState.focused;
        this.damaged = true;
      }else if(focus && (this.state & WidgetState.focused) == 0 ){
        this.state  |= WidgetState.focused;
        this.damaged = true;
      }
      return this._focused;
    }//set_focus

    //is widget focused?
    public override bool get_focus(){
      return this._focused;
    }//get_focus

//~   bool term_draw_cb (Gtk.Widget    widget,Cairo.Context cr2){
    public override bool draw(Cairo.Context cr2){
      var _ret = base.draw(cr2);
      
      int64 start, end;
      if(!this.initialized) return false;
      start=GLib.get_monotonic_time();

//https://developer.gnome.org/gtk3/stable/chap-drawing-model.html#double-buffering

//~       this. begin_paint_region
//~       this.terminal_db_image.flush();
      cr2.save();
      cr2.set_font_size ( (18));



//~        terminal_db_cr.move_to(0, 0);
      double cx1,cx2,cy1,cy2;
      uint x1,x2,y1,y2, charscount=0;
      Tsm.Tsmage prev_age2 = this.prev_age;
      cr2.clip_extents( out cx1, out cy1, out cx2, out cy2);
//~       var clip_rectangle = Cairo.Region.rectangle();

//~       Gdk.Rectangle grect={(int)x1,(int)y1,(int)(x2-x1),(int)(y2-y1)};
//~       widget.get_window ().begin_paint_rect(grect);

//~       terminal_db_cr.rectangle(x1, y1, x2, y2);
//~       terminal_db_cr.fill();
//~       cr2.restore();
//~       terminal_db_cr.move_to(x1, y1);
//~       cr2.save();
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

      x1 = (uint)(cx1 / (double)this.cell_width);
      x2 = (uint)(cx2 / (double)this.cell_width);
      y1 = (uint)(cy1 / (double)this.cell_height);
      y2 = (uint)(cy2 / (double)this.cell_height);
      x1=( x1 > 0 ? x1 -1 : x1);x2+=1;
      y1=( y1 > 0 ? y1 -1 : y1);y2+=1;

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

//~                 printf("=%dx%d age=%d prev_age=%d\n",(int)posx,(int)posy,(int)age, (int)prev_age);

               if(this.prev_age>0 &&  age <= this.prev_age){
                return 0;//skip draw if not enough old
                }

            }
            charscount++;
//~                 printf("=%dx%d age=%d prev_age=%d\n",(int)posx,(int)posy,(int)age, (int)prev_age);

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
//~             br += 0x80; br = (br + (br >> 8)) >> 8;// br /= 255.0;
//~             bg += 0x80; bg = (bg + (bg >> 8)) >> 8;
//~             bb += 0x80; bb = (bb + (bb >> 8)) >> 8;

            cr2.set_source_rgb(
                     br/255.0,
                     bg/255.0,
                     bb/255.0);

            cr2.rectangle(posx*this.cell_width, posy*this.cell_height, this.cell_width, this.cell_height);
            cr2.fill();

            if(len>0){
              //text
//~               cr2.save();
//~               if(ch=="")ch=" ";

              size_t ulen=0;
              string  cval = Tsm.ucs4_to_utf8_alloc(ch, len, out ulen);

              var val=cval.substring(0,(long)ulen);

              var x = posx * this.cell_width;
              var y = posy * this.cell_height - this.cell_bearing;

              cr2.move_to(x, y);
//~               fr += 0x80; fr = (fr + (fr >> 8)) >> 8;
//~               fg += 0x80; fg = (fg + (fg >> 8)) >> 8;
//~               fb += 0x80; fb = (fb + (fb >> 8)) >> 8;

              cr2.set_source_rgb(
                       fr/255.0,
                       fg/255.0,
                       fb/255.0);
              cr2.show_text(val);//(string)val

//~               cr2.restore();
              }
        return 0;
        });

//~   this.prev_age++;//<=

  cr2.restore();

//~   if(charscount>0)
//~     this.terminal_db_image.mark_dirty();

//~   cr2.set_source_rgba (0, 0, 0,1);
//~   cr2.paint();
//~   cr2.set_source_surface(cr2.get_target (), 0, 0);
//~   cr2.get_source().set_filter (Cairo.Filter.NEAREST);
//~   cr2.paint();


//~     widget.get_window ().end_paint();//notify for single buffer mode

    end = GLib.get_monotonic_time();
    var dtime=(end - start) / 1000;
    if (dtime>2){
      print("draw: %lldms widg=%p force=%d \n", dtime,this,this.force_redraw);
      print("term_draw_cb l=%d t=%d r=%d b=%d \n",(int)x1,(int)y1,(int)x2,(int)y2);
    }
    print("total=%d prev_age=%d prev_age2=%d\n\n",(int)charscount,(int)this.prev_age,(int)prev_age2);
    this.force_redraw=false;
    return _ret;//stop other handlers from being invoked for the event
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
    Ltk.Global.quit();
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
          Ltk.Global.quit();
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
          Ltk.Global.quit();
          return true;
        }

        pid = this.pty.get_child();
        this.child_src = GLib.ChildWatch.add(pid, term_child_exit_cb);

        this.term_notify_resize();


        return true;
  }//start_terminal

  public override void allocation_changed(){
    if(!this.initialized){
      }
    this.term_recalc_cells();
    this.term_notify_resize();
  }

  void my_tsmlog(
			   string file,
			   int line,
			   string func,
			   string subs,
			   uint sev,
			   string format,
			   va_list args){
        printf("my_tsmlog\n");
  }

  //constructor
  public TSMterm(){
    
      this.min_width = 50;
      this.min_height = 50;



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

//~       this.font_desc = new Pango.FontDescription();
//~       this.font_desc.set_family("Mono");
//~       this.font_desc.set_size((int)(12 * Pango.SCALE));

//~       //virtual surface
//~       var surface = new Cairo.ImageSurface(Cairo.Format.RGB24, 2000, 500);
//~       var cr = new Cairo.Context(surface);
//~       var layout = Pango.cairo_create_layout(cr);
//~       layout.set_font_description(this.font_desc);

//~       layout.set_height(0);
//~       layout.set_spacing(0);

//~       layout.set_text( str, str.length);

//~       Pango.Rectangle rect;
//~       layout.get_pixel_extents( null, out rect);


//~       this.cell_width = (rect.width + (str.length - 1)) / str.length;
//~       this.cell_height = rect.height;

      printf("cell_width=%d cell_height=%d\n",(int)this.cell_width,(int)this.cell_height);

  }//constructor

    /* print names of modifiers present in mask */
    private void
    print_modifiers (uint32 mask)
    {
        string MODIFIERS[] = {
                "Shift", "Lock", "Ctrl", "Alt",
                "Mod2", "Mod3", "Mod4", "Mod5",
                "Button1", "Button2", "Button3", "Button4", "Button5"
        };

        printf ("Modifier mask: ");
        for (int i=0 ; mask>0; mask >>= 1, ++i) {
            if ( (mask & 1) == 1) {
                printf (MODIFIERS[i]);
            }
        }
        printf ("\n");
    }

  public override void on_key_press(uint keycode, uint state){
      uint32 ucs4;
      uint mods = 0;
//~       Gdk.ModifierType cmod;
      uint key;

//~       if(this.keymap == null){
//~         this.keymap = Gdk.Keymap.get_default();
//~       }

/*      if(this.keymap.translate_keyboard_state(
          e.hardware_keycode,
          e.state,
          e.group,
          out key,
          null,
          null,
          out cmod)){

        if (key == Gdk.Key.Up &&
            ((e.state & ~cmod & ALL_MODS) == Gdk.ModifierType.SHIFT_MASK)) {
          this.screen.sb_up( 1 );
          this.tarea.queue_draw();
          return true;
        } else if (key == Gdk.Key.Down &&
            ((e.state & ~cmod & ALL_MODS) == Gdk.ModifierType.SHIFT_MASK)) {
          this.screen.sb_down( 1 );
          this.tarea.queue_draw();
          return true;
        } else if (key == Gdk.Key.Page_Up &&
            ((e.state & ~cmod & ALL_MODS) == Gdk.ModifierType.SHIFT_MASK)) {
          printf("sb_page_up\n");
          this.screen.sb_page_up( 1 );
          this.tarea.queue_draw();
          return true;
        } else if (key == Gdk.Key.Page_Down &&
            ((e.state & ~cmod & ALL_MODS) == Gdk.ModifierType.SHIFT_MASK)) {
          this.screen.sb_page_down( 1 );
          this.tarea.queue_draw();
          return true;
        }

      }*/

      if ( (state & Xkb.ModifierType.SHIFT_MASK) == Xkb.ModifierType.SHIFT_MASK)
        mods |= Tsm.Vte_modifier.SHIFT_MASK;
      if ( (state & Xkb.ModifierType.LOCK_MASK) == Xkb.ModifierType.LOCK_MASK)
        mods |= Tsm.Vte_modifier.LOCK_MASK;
      if ( (state & Xkb.ModifierType.CONTROL_MASK) == Xkb.ModifierType.CONTROL_MASK)
        mods |= Tsm.Vte_modifier.CONTROL_MASK;
      if ( (state & Xkb.ModifierType.MOD1_MASK) == Xkb.ModifierType.MOD1_MASK)
        mods |= Tsm.Vte_modifier.ALT_MASK;
      if ( (state & Xkb.ModifierType.MOD4_MASK) == Xkb.ModifierType.MOD4_MASK)
        mods |= Tsm.Vte_modifier.LOGO_MASK;

      print_modifiers(state);
      ucs4 = xkb_keysym_to_utf32(keycode);
      debug("TSMterm: on_key_press ucs4=%u keycode=%u mods=%u state=%u ",ucs4,keycode,mods,state);
      if (ucs4 == 0)
        ucs4 = Tsm.TSM_VTE_INVALID;

      if (this.vte.handle_keyboard(keycode, 0, mods, ucs4)) {
        this.screen.sb_reset();
        return;
      }

      return;
    }//on_key_press

  void term_recalc_cells()
  {
      const string str = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ@!\"$%&/()=?\\}][{°^~+*#'<>|-_.:,;`´ ";

      var terminal_db_image = new Cairo.ImageSurface (Cairo.Format.ARGB32, int.max((int)this.A.width,(int)this.min_width), int.max((int)this.A.height,(int)this.min_height));
      var cr    = new Cairo.Context (terminal_db_image);

//~       this.terminal_db_cr.select_font_face ( "Mono",
//~                   Cairo.FontSlant.NORMAL, Cairo.FontWeight.NORMAL);
//~                   Cairo.FontSlant.NORMAL, Cairo.FontWeight.BOLD);
      cr.set_font_face(Ltk.Global.Font);
      cr.set_font_size ( (18));

      Cairo.TextExtents extents;
      cr.text_extents (str, out extents);


      this.cell_width = ((int)extents.width + (str.length - 1)) / str.length;
      this.cell_height = (int)extents.height+0;
      this.cell_bearing = (int)extents.y_bearing-1;//one pixel offset


      this.force_redraw=true;//redraw whole window


    this.columns = this.A.width / this.cell_width;
    this.rows = this.A.height / this.cell_height;

    if (this.columns == 0)
      this.columns = 1;
    if (this.rows == 0)
      this.rows = 1;

    this.initialized=true;
  }
}

int main (string[] argv) {

  Ltk.Global.Init(true,"/usr/share/fonts/truetype/dejavu/DejaVuSansMono.ttf");

  var window = new Ltk.Window();
  window.have_background=false;
  window.place_policy = Ltk.SOptions.place_horizontal;
  window.fill_mask = Ltk.SOptions.fill_vertical | Ltk.SOptions.fill_horizontal;
  window.set_title("TSMterm");

  var term = new TSMterm();
  term.have_background=false;
  term.fill_mask = Ltk.SOptions.fill_vertical | Ltk.SOptions.fill_horizontal;
  term.show();
  
  window.add(term);

  window.show();
  window.size_request(800,600);

  Ltk.Global.run();
//~   GLib.stdin.read_line ();
return 0;
}
