using Posix;
using Ltk;

//~ [CCode (cname = "execve")]
//~ extern int execve(string path, string[] arg, string[] environ);

//~ const Gdk.ModifierType ALL_MODS = (Gdk.ModifierType.SHIFT_MASK | Gdk.ModifierType.LOCK_MASK | Gdk.ModifierType.CONTROL_MASK |	  Gdk.ModifierType.MOD1_MASK | Gdk.ModifierType.MOD4_MASK);

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
  private Ltk.Allocation damage_region;
  private uint draw_callback_timer;


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
  HashTable<uint32?, uint32> glyphs; //unicode to gliph


  void mylog(
           string file,
           int line,
           string func,
           string subs,
           uint sev,
           string format,
           va_list args){
    debug("%s: %s: ", sev.to_string(), subs);
    debug(format, args);
    debug("\n");
  }
  
//~   void debug(string format, ...){
//~     va_list list = va_list ();
//~     GLib.stderr.vprintf(format, list);
        //for (int? y = list.arg<int?> (); y != null; y = list.arg<int?> ()) {
        //    result += y;
        //}
//~   }
  void debug(string format, ...){
  }

  public void my_write_cb(Tsm.Vte vte, char* u8,  size_t len){
    int r;

    r = this.pty.write(u8, len);
    if (r < 0)
      debug("OOM in pty-write (%d)", r);

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
      debug("bridge dispatch failed (%d)", r);
    return true;
  }

  public void term_read_cb(Shlpty.Shlpty shelpty, char *u8,size_t len){
//~     debug("new char:%s\n",(string)u8);
    this.vte.input(u8, len);
    this.damaged = true;//redraw with new state
  }

  void term_notify_resize()
  {
    int r;

    r = this.screen.resize(this.columns, this.rows);
    if (r < 0)
      debug("cannot resize TSM screen (%d)", r);

    r = this.pty.resize((ushort)this.columns, (ushort)this.rows);
    if (r < 0)
      debug("cannot resize pty (%d)", r);
  }


  int screen_draw_cb (Tsm.Screen screen,
				   uint32 id,
				   uint32* ch,
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

        this.damage(ref this.damage_region , posx*this.cell_width,posy*this.cell_height,this.cell_width,this.cell_height);

        return 0;
    }//screen_draw_cb

//~   bool term_draw_cb (Gtk.Widget    widget,Cairo.Context cr2){
    public override bool draw(Cairo.Context cr2){
      var _ret = base.draw(cr2);
      
      if(!this.initialized) return false;
      
      /*Posix.timespec startspec,endspec;
      Posix.clock_gettime(Posix.CLOCK_PROCESS_CPUTIME_ID, out startspec);
      debug("posixtimes=%d\n",(int)startspec.tv_nsec);
      */ 

//https://developer.gnome.org/gtk3/stable/chap-drawing-model.html#double-buffering

      cr2.save();
      cr2.set_font_size ( (12));

      double cx1,cx2,cy1,cy2;
      uint x1,x2,y1,y2, charscount=0;
      Tsm.Tsmage prev_age2 = this.prev_age;
      cr2.clip_extents( out cx1, out cy1, out cx2, out cy2);


      x1 = (uint)(cx1 / (double)this.cell_width);
      x2 = (uint)(cx2 / (double)this.cell_width);
      y1 = (uint)(cy1 / (double)this.cell_height);
      y2 = (uint)(cy2 / (double)this.cell_height);
      x1=( x1 > 0 ? x1 -1 : x1);x2+=1;
      y1=( y1 > 0 ? y1 -1 : y1);y2+=1;
      
      this.reset_damage(ref this.damage_region);
      
      Ltk.Allocation cairo_damage_region={};
      
      this.reset_damage(ref cairo_damage_region);

      Cairo.Glyph dglyph[500]; //MAX_GLYPH_CHUNKS max chunk size 500
      int dglyph_len=0;

//~     	Tsm.Tsmage age = this.screen.draw(screen_draw_cb);
      uint8 Br=1, Bg=2, Bb=3;
      uint8 Fr=1, Fg=2, Fb=3;
      
      int lastposx = -1;
      int lastposy = -1;
      uint lastinv = 0, lastcharcount = 0;

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

//~                 debug("=%dx%d age=%d prev_age=%d\n",(int)posx,(int)posy,(int)age, (int)prev_age);

               if(this.prev_age>0 &&  age <= this.prev_age){
                return 0;//skip draw if not enough old
                }

            }
            charscount++;
            lastcharcount++;
            this.damage(ref this.damage_region, posx*this.cell_width,
                                                posy*this.cell_height,
                                                this.cell_width,
                                                this.cell_height);



//~                 print("=%dx%d age=%d prev_age=%d\n",(int)posx,(int)posy,(int)age, (int)prev_age);


            // invert colors if requested
            uint8 fr=0, fg=0, fb=0, br=0, bg=0, bb=0;
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

//~             print("(%dx%d %2x%2x%2x %2x%2x%2x i%dc%dl%d) ",(int)posx,(int)posy,(int)br,(int)bg,(int)bb,(int)fr,(int)fg,(int)fb,(int)attr.inverse,(int)*ch,(int)dglyph_len);

            

            if(lastposy < 0) {
              lastposx = (int)posx;
              lastposy = (int)posy;
              Br = br;
              Bg = bg;
              Bb = bb;

              Fr = fr;
              Fg = fg;
              Fb = fb;
              
              lastinv = attr.inverse;
            }else
              if(Br != br  ||
                 Bg != bg  ||
                 Bb != bb  ||
                 Fr != fr  ||
                 Fg != fg  ||
                 Fb != fb  ||
                (lastposx+1) != posx ||
                lastposy != posy ||
                lastinv != attr.inverse ||
                dglyph_len == 500){
                  //concatenate sequential cells with same bg/fg
                  // ((lastposx+1) != posx) and (lastposy != posy) - check for sequences

                  cr2.set_source_rgb( 
                           Br/255.0,
                           Bg/255.0,
                           Bb/255.0);
//~                   print("[%dx%d/%d] ",(int)posx,(int)posy,(int)lastposy);
//~                   print(" - %dx%d w%dh%d - ",
//~                                  (int)((int)cairo_damage_region.x/this.cell_width), 
//~                                  (int)((int)cairo_damage_region.y/this.cell_height), 
//~                                  (int)(cairo_damage_region.width-cairo_damage_region.x)/(int)this.cell_width, 
//~                                  (int)(cairo_damage_region.height-cairo_damage_region.y)/(int)this.cell_height );
                                 
                  cr2.rectangle( cairo_damage_region.x, 
                                 cairo_damage_region.y, 
                                 cairo_damage_region.width-cairo_damage_region.x, 
                                 cairo_damage_region.height-cairo_damage_region.y);
                  cr2.fill();

//~                   print("< %dc%d \n",(int)lastcharcount,(int)dglyph_len);
                  
                  if( dglyph_len > 0 ){
                    cr2.set_source_rgb(
                             Fr/255.0,
                             Fg/255.0,
                             Fb/255.0);

                    my_cairo_show_glyphs(cr2,(Cairo.Glyph[])dglyph,dglyph_len);
                    //cr2.show_glyphs ((Cairo.Glyph[])dglyph.data);//TODO: not working in vala 40
                    
                    dglyph_len=0;
                }
                  
                  Br = br;
                  Bg = bg;
                  Bb = bb;
                  
                  Fr = fr;
                  Fg = fg;
                  Fb = fb;
                  this.reset_damage(ref cairo_damage_region);//reset region for next chunk
                  
                  lastinv = attr.inverse;
                  lastcharcount=0;
                }
            
            this.damage(ref cairo_damage_region, 
                        posx*this.cell_width,
                        posy*this.cell_height,
                        this.cell_width,
                        this.cell_height);

            if(len > 0){
              var x = posx * this.cell_width;
              var y = posy * this.cell_height - this.cell_bearing;

              
              uint32? index = this.glyphs.lookup(*ch);
//~                 print("ch=%d index=%d\n",(int)*ch,(int)index);

              if(index != 0){
                dglyph[dglyph_len].index = index;
              }else{
                //[CCode (free_function = "cairo_glyph_free")] TODO
                Cairo.Glyph[] tmpglyph;

                string?  val=((string32)ch).to_utf8(1); //UCS4 to UTF8
                
                var font = cr2.get_scaled_font ();
                font.text_to_glyphs (0, 0,
                          val, (int)val.length,
                          out  tmpglyph,
                          null, null);
                
                if(tmpglyph != null){
                  this.glyphs.insert(*ch, (uint32)tmpglyph[0].index);
                  dglyph[dglyph_len].index = tmpglyph[0].index;
                }

              }
              dglyph[dglyph_len].x = x;
              dglyph[dglyph_len++].y = y;
            }//if len > 0

        lastposx = (int)posx;
        lastposy = (int)posy;

        return 0;
        });
/********/

    //draw last part that was not drawn in loop
//~     print("{%d %d} ",(int)lastposy,(int)dglyph_len);
    cr2.set_source_rgb(
             Br/255.0,
             Bg/255.0,
             Bb/255.0);

    cr2.rectangle( cairo_damage_region.x, 
                   cairo_damage_region.y, 
                   cairo_damage_region.width-cairo_damage_region.x, 
                   cairo_damage_region.height-cairo_damage_region.y);

    cr2.fill();


    if(dglyph_len > 0){
      cr2.set_source_rgb(
               Fr/255.0,
               Fg/255.0,
               Fb/255.0);
      my_cairo_show_glyphs(cr2,(Cairo.Glyph[])dglyph,dglyph_len);
      dglyph_len=0;
    }

//~     print("{%dx%d/%dx%d} ",(int)prevposx,(int)prevposy,(int)lastposx,(int)lastposy);

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

      var win = get_top_window();
      if(win != null){
        var xcb = win.get_xcb_window();
        xcb.reset_damage();
        debug( "TERM **** damage xy=%u,%u wh=%u,%u\n",
        this.damage_region.x,
        this.damage_region.y,
        this.damage_region.width-this.damage_region.x,
        this.damage_region.height-this.damage_region.y);
        xcb.damage(this.damage_region.x,
                       this.damage_region.y,
                       this.damage_region.width-this.damage_region.x,
                       this.damage_region.height-this.damage_region.y );
      }


    /*Posix.clock_gettime(Posix.CLOCK_PROCESS_CPUTIME_ID, out endspec);
    
    uint64 fff = (startspec.tv_sec * 1000000000) + startspec.tv_nsec;
    uint64 fff2 = (endspec.tv_sec * 1000000000) + endspec.tv_nsec;

    debug("posixtimes=%dn\n",(int)(fff2-fff));


//~     var dtime=(end - start) / 1000;
    var dtime = (fff2-fff)/1000000;
    if (dtime>0){
      debug("draw: %lldms widg=%p force=%d \n", dtime,this,this.force_redraw);
      debug("term_draw_cb l=%d t=%d r=%d b=%d \n",(int)x1,(int)y1,(int)x2,(int)y2);
    }

    debug("total=%d prev_age=%d prev_age2=%d\n\n",(int)charscount,(int)this.prev_age,(int)prev_age2);
    */

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
    debug("Starting %s",argv[0]);
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
      debug("Shlpty.Shlpty.open\n");
      GLib.stdout.flush();
      r = Shlpty.Shlpty.open(out this.pty, term_read_cb,
             (ushort)this.columns, (ushort)this.rows);

        if (r < 0) {
          debug("cannot spawn pty (%d)\n", r);
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
          debug("cannot add pty to bridge (%d)\n", r);
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
        debug("my_tsmlog\n");
  }

  //constructor
  public TSMterm(){
      this.min_width = 50;
      this.min_height = 50;
      this.glyphs = new HashTable<uint32?, uint32> (int_hash, int_equal);



      if (Tsm.Screen.Screen_new(out  this.screen, this.mylog) <0){
        debug("Unable to create screen");
        exit(1);
      }
      this.screen.set_max_sb(5000);
      if( Tsm.Vte.Vte_new(out this.vte,
                  this.screen,
                  this.my_write_cb,
                  this.mylog) < 0 ){
        debug("Unable to create vte");
        exit(1);
      }

      this.pty_bridge=Shlpty.Bridge.Bridge_new();

      if (this.pty_bridge < 0) {
        debug("Unable to create pty_bridge");
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

      debug("cell_width=%d cell_height=%d\n",(int)this.cell_width,(int)this.cell_height);

  }//constructor

  public override void on_key_press(uint keycode, uint state){
      uint32 ucs4;
      uint mods = 0;
      if (keycode == Xkb.Key.Up &&
          ((state & Xkb.ModifierType.SHIFT_MASK)>0)) {
        this.screen.sb_up( 1 );
        this.damaged = true;//redraw with new state
        return;
      } else if (keycode == Xkb.Key.Down &&
          ((state & Xkb.ModifierType.SHIFT_MASK)>0)) {
        this.screen.sb_down( 1 );
        this.damaged = true;//redraw with new state
        return;
      } else if (keycode == Xkb.Key.Page_Up &&
          ((state & Xkb.ModifierType.SHIFT_MASK)>0)) {
        debug("sb_page_up\n");
        this.screen.sb_page_up( 1 );
        this.damaged = true;//redraw with new state
        return;
      } else if (keycode == Xkb.Key.Page_Down &&
          ((state & Xkb.ModifierType.SHIFT_MASK)>0)) {
        this.screen.sb_page_down( 1 );
        this.damaged = true;//redraw with new state
        return;
      }


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

      ucs4 = xkb_keysym_to_utf32(keycode);
      ltkdebug("TSMterm: on_key_press ucs4=%u keycode=%u mods=%u state=%u ",ucs4,keycode,mods,state);
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
//~       const string str = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ@!\"$%&/()=?\\}][{°^~+*#'<>|-_.:,;`´ ";
      const string str = "1234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ@!\"$%&/()=?\\}][{^~+*#'<>|-_.:,;`";

      var terminal_db_image = new Cairo.ImageSurface (Cairo.Format.A8, 1,1);
      var cr    = new Cairo.Context (terminal_db_image);

//~       this.terminal_db_cr.select_font_face ( "Mono",
//~                   Cairo.FontSlant.NORMAL, Cairo.FontWeight.NORMAL);
//~                   Cairo.FontSlant.NORMAL, Cairo.FontWeight.BOLD);
      cr.set_font_face(Ltk.Global.Font);
      cr.set_font_size ( (12));

      Cairo.TextExtents extents;
      cr.text_extents (str, out extents);


      this.cell_width = ((int)extents.width + (str.length - 1)) / str.length;
      this.cell_height = (int)extents.height+3;
      this.cell_bearing = (int)extents.y_bearing-3;//one pixel offset

      var text_x = 0 * this.cell_width;
      var text_y = 0 * this.cell_height - this.cell_bearing;


      var font = cr.get_scaled_font ();
      
      Cairo.Glyph[]? glyphstmp = null;
//~       TextCluster[] clusters;
//~       TextClusterFlags cluster_flags;
      
      font.text_to_glyphs (text_x, text_y,
                str, (int)str.length,
                out  glyphstmp,
                null, null);

//~       long codepoint_count;
//~       string utf32_version = str.to_utf32_fast(-1, out codepoint_count).to_string();

      debug("glyphstmp=%d str=%d ptr=%d\n",glyphstmp.length,str.length,(int)font);

      if(str.length == glyphstmp.length){
        for( int i =0; i < glyphstmp.length;i++){
  //~         glyphs.insert((uint32) str.get_char(i),glyphstmp[i]);
          uint32 c32 = (uint32) str.get_char(i);
          debug("c32=%d g=%d %c == %c | ",(int)c32,(int)glyphstmp[i].index,(char)c32,(char)c32);
  //~         unowned Cairo.Glyph[]? glyphstmp2  = glyphstmp;
  //~         void* p = (void*)&glyphstmp2[i];
  //~         int i32 = (int)c32;
          glyphs.insert(c32,(uint32)glyphstmp[i].index);
//~           this.glyphs[ (c32 & 0xFF) ] = (Cairo.Glyph?)&glyphstmp[i];
        }
      }


      this.force_redraw=true;//redraw whole window


    this.columns = this.A.width / this.cell_width;
    this.rows = this.A.height / this.cell_height;

    if (this.columns == 0)
      this.columns = 1;
    if (this.rows == 0)
      this.rows = 1;

    this.initialized=true;
  }
  private bool _selection = false;
    public override void on_button_press(uint button, uint state,uint x, uint y){
		ltkdebug("on_button_press %u %u",button,state);
      if(button == 1 && (state & Xcb.ModMask.SHIFT)>0){
        this.screen.selection_start((x/this.cell_width),(y/this.cell_height));
        this.damaged = true;//redraw button with new state
        _selection=true;
      }
    }
    public override void on_button_release(uint button, uint state,uint x, uint y){
      if(button == 1 && _selection){
        this.screen.selection_target((x/this.cell_width),(y/this.cell_height));
        this.damaged = true;//redraw button with new state
        _selection=false;
      }else{
        string seltxt;
        this.screen.selection_copy(out seltxt);
        ltkdebug("selection=%s",seltxt);
      }
    }

    public void damage(ref  Ltk.Allocation region,uint x,uint y,uint width,uint height){
//~       ltkdebug( "TERM **** damage");
      region.x = uint.min(region.x, x);
      region.y = uint.min(region.y, y);
      region.width = uint.max(region.width, x+width);//x2
      region.height = uint.max(region.height, y+height);//y2
    }

    public void reset_damage(ref Ltk.Allocation region){
      region.width = region.height = 0;
      region.x     = region.y = (uint32)0xFFFFFFFF;
    }

/*    private void do_draw(){
      this.draw_area(this.damage_region.x,
                     this.damage_region.y,
                     this.damage_region.width-this.damage_region.x,
                     this.damage_region.height-this.damage_region.y );
      this.reset_damage();
    }
    
    private bool on_timeout(){
      this.do_draw();
      this.draw_callback_timer = 0;
      return GLib.Source.REMOVE;//done
    }

    private void queue_draw(){
      if(this.draw_callback_timer == 0){
//~         GLib.Source.remove(draw_callback_timer);
        this.draw_callback_timer = GLib.Timeout.add((1000/30),on_timeout);
      }
    }

    public void cancel_draw(){
      if(this.draw_callback_timer != 0){
        GLib.Source.remove(draw_callback_timer);
        draw_callback_timer=0;
      }
    }*/


}//class TSMterm

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

  window.size_request(800,600);
  window.show();

  term.set_focus(true);

  Ltk.Global.run();
//~   GLib.stdin.read_line ();
return 0;
}
