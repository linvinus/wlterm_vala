/*
 * libtsm - Terminal-Emulator State Machine
 *
 * Copyright (c) 2012-2013 David Herrmann <dh.herrmann@gmail.com>
 *
 * Permission is hereby granted, free of charge, to any person obtaining
 * a copy of this software and associated documentation files
 * (the "Software"), to deal in the Software without restriction, including
 * without limitation the rights to use, copy, modify, merge, publish,
 * distribute, sublicense, and/or sell copies of the Software, and to
 * permit persons to whom the Software is furnished to do so, subject to
 * the following conditions:
 *
 * The above copyright notice and this permission notice shall be included
 * in all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
 * OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
 * MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
 * IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
 * CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
 * TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
 * SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 */


[CCode (cname = "xkb_keysym_to_utf32")]
extern uint32 xkb_keysym_to_utf32(uint key);


[CCode (lower_case_cprefix = "tsm_", cheader_filename = "libtsm.h")]
namespace Tsm {

    /* keep in sync with shl_xkb_mods */
    [CCode (cname = "tsm_vte_modifier", cprefix = "TSM_", has_type_id = false)]
    enum Vte_modifier {
      SHIFT_MASK		= (1 << 0),
      LOCK_MASK		= (1 << 1),
      CONTROL_MASK	= (1 << 2),
      ALT_MASK		= (1 << 3),
      LOGO_MASK		= (1 << 4)
    }
    [CCode (cname = "TSM_VTE_INVALID")]
    const uint32 TSM_VTE_INVALID;

//~ 	tsm_ucs4_get_width;
//~ 	tsm_ucs4_to_utf8;
//~ 	tsm_ucs4_to_utf8_alloc;
//~   struct tsm_vte *vte;

    static size_t ucs4_to_utf8(uint32* ucs4, string data_out);
    static string ucs4_to_utf8_alloc(uint32* ucs4, size_t len, out size_t len_out);

    [CCode (cname = "struct tsm_screen_attr", destroy_function = "")]
    public struct screen_attr {
      public int8 fccode;			/* foreground color code or <0 for rgb */
      public int8 bccode;			/* background color code or <0 for rgb */
      public uint8 fr;			/* foreground red */
      public uint8 fg;			/* foreground green */
      public uint8 fb;			/* foreground blue */
      public uint8 br;			/* background red */
      public uint8 bg;			/* background green */
      public uint8 bb;			/* background blue */
      [CCode (default_value = "\'\\1\'")]
      public uint bold;		/* bold character */
      [CCode (default_value = "\'\\1\'")]
      public uint underline;	/* underlined character */
      [CCode (default_value = "\'\\1\'")]
      public uint inverse;	/* inverse colors */
      [CCode (default_value = "\'\\1\'")]
      public uint protect;	/* cannot be erased */
      [CCode (default_value = "\'\\1\'")]
      public uint blink;		/* blinking character */
    }


    [CCode (cname = "tsm_log_t",instance_pos = 0)]
    public delegate void Tsmlog(
			   string file,
			   int line,
			   string func,
			   string subs,
			   uint sev,
			   string format,
			   va_list args);

    [CCode (cname = "tsm_vte_write_cb")] //, instance_pos = 1.9
    public delegate void Tsmvte_write_cb(Tsm.Vte vte,
				  char* u8,
				  size_t len);

    [SimpleType]
    [CCode (cname = "tsm_symbol_t", has_type_id = false)]
    public struct Tsmsymbol : uint32 {
    }

    [SimpleType]
    [CCode (cname = "tsm_age_t", has_type_id = false)]
    public struct Tsmage : uint32 {
    }


[CCode (cname = "tsm_screen_draw_cb",instance_pos = -1)]
public delegate  int Tsm_screen_draw_cb (Screen screen,
				   uint32 id,
				   uint32* ch,
				   size_t len,
				   uint width,
				   uint posx,
				   uint posy,
				   screen_attr attr,
				   Tsmage age );


  [Compact]
  [CCode(cname = "struct tsm_screen",
         cprefix = "tsm_screen_",
         ref_function = "tsm_screen_ref",
         unref_function = "tsm_screen_unref",
         ref_function_void = true)]
    public class Screen {

      [CCode (cname = "tsm_screen_new")]
      public static int Screen_new( out Screen screen,Tsmlog log); //[CCode (type = "struct tsm_screen**")]
//~       [CCode (cname = "tsm_screen_ref")]
//~       public void ref();
//~       [CCode (cname = "tsm_screen_unref")]
//~       public void unref();

      public uint get_width();
      public uint get_height();
      public int  resize(uint x, uint y);
      public int  set_margins(uint top, uint bottom);
      public void set_max_sb(uint max);
      public void clear_sb();

      public void sb_up( uint num);
      public void sb_down( uint num);
      public void sb_page_up( uint num);
      public void sb_page_down( uint num);
      public void sb_reset();

      public void set_def_attr(screen_attr attr);
      public void reset();
      public void set_flags( uint flags);
      public void reset_flags( uint flags);
      public uint get_flags();

      public uint get_cursor_x();
      public uint get_cursor_y();

      public void set_tabstop();
      public void reset_tabstop();
      public void reset_all_tabstops();

      public void write( Tsmsymbol ch, screen_attr attr);
      public void newline();
      public void scroll_up( uint num);
      public void scroll_down( uint num);
      public void move_to( uint x, uint y);
      public void move_up( uint num, bool scroll);
      public void move_down( uint num, bool scroll);
      public void move_left( uint num);
      public void move_right( uint num);
      public void move_line_end();
      public void move_line_home();
      public void tab_right( uint num);
      public void tab_left( uint num);
      public void insert_lines( uint num);
      public void delete_lines( uint num);
      public void insert_chars( uint num);
      public void delete_chars( uint num);
      public void erase_cursor();
      public void erase_chars( uint num);
      public void erase_cursor_to_end( bool protect);
      public void erase_home_to_cursor( bool protect);
      public void erase_current_line( bool protect);
      public void erase_screen_to_cursor( bool protect);
      public void erase_cursor_to_screen( bool protect);
      public void erase_screen( bool protect);

      public void selection_reset();
      public void selection_start(uint posx, uint posy);
      public void selection_target(uint posx, uint posy);
      public int selection_copy([CCode (type = "char**")] out string text);
      public Tsmage draw( Tsm_screen_draw_cb draw_cb);
    }//Screen

//~     [CCode (cheader_filename = "libtsm.h")]
    [Compact]
    [CCode (cname = "struct tsm_vte",
            cprefix = "tsm_vte_",
            ref_function = "tsm_vte_ref",
            unref_function = "tsm_vte_unref",
            ref_function_void = true)]
    public class Vte {
      [CCode (cname = "tsm_vte_new")]
      public static int Vte_new(out Vte vte,
          Screen screen,
          Tsmvte_write_cb write_cb,
          Tsmlog log);

      public int set_palette(string palette);

      public void reset();
      public void hard_reset();
      public void input(uchar* u8, size_t len);
      public bool handle_keyboard(uint32 keysym,
                 uint32 ascii, uint mods,
                 uint32 unicode);

    }//class Vte
}
