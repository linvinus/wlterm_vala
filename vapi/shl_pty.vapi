
[CCode (lower_case_cprefix = "shl_pty_", cheader_filename = "shl_pty.h")]
namespace Shlpty {

    [CCode (cname = "shl_pty_input_cb")] //has_target = false, instance_pos = 1.9
    public delegate void Shlpty_input_cb(Shlpty shelpty, char *u8,
              size_t len);

  [Compact]
  [CCode(cname = "struct shl_pty",
         cprefix = "shl_pty_",
         ref_function = "shl_pty_ref",
         unref_function = "shl_pty_unref",
         ref_function_void = true)]
    public class Shlpty {
//~       [CCode (instance_pos = -3)] [CCode (type = "struct shl_pty **")] 
      public static Posix.pid_t open(out Shlpty shlpty,
             [CCode (target_pos=-1)]Shlpty_input_cb cb,
             /*void *data,*/
             ushort term_width,
             ushort term_height);

      public void close();
      public bool is_open();
      public int get_fd();
      public Posix.pid_t get_child();

      public int dispatch();
      public int write( char* u8, size_t len);
      public int signal( int sig);
      public int resize(
             ushort term_width,
             ushort term_height);
    }//class Shlpty

    [SimpleType]
    [CCode (cname = "int",
            has_type_id = false,
            cprefix = "shl_pty_bridge_",
            ref_function = "",
            unref_function = "",
            ref_function_void = true)]
    public struct Bridge : int {
      [CCode (cname = "shl_pty_bridge_new")]
      public static Bridge Bridge_new();
      public void free();

      public int dispatch(int timeout);
//~       [CCode (instance_pos = 1.9)]
      public int add( Shlpty pty);
//~       [CCode (instance_pos = 1.9)]
      public void remove(Shlpty pty );
  }
  
}//namespace Shlpty
