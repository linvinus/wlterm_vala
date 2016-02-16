
[SimpleType]
[CCode (cname = "key_t", has_type_id = false)]
public struct Shm_key : int32 {
}

/* Mode bits for `msgget', `semget', and `shmget'.  */
[CCode ( cprefix = "IPC_", has_type_id = false)]
enum IPC {
  CREAT,  /* Create key if key does not exist. */
  EXCL,   /* Fail if key exists.  */
  NOWAIT,  /* Return error on wait.  */
  STAT,
  SET,
  RMID
}


[SimpleType]
[CCode (cname = "int",
        has_type_id = false,
        cprefix = "shm",
        ref_function = "",
        unref_function = "",
        ref_function_void = true,
        cheader_filename = "sys/shm.h")]
public struct Shm : int {

    public static Shm get(Shm_key key, size_t size, int shmflg);

    public static void * at(Shm shmid,void * shmaddr, int shmflg);

    public static int dt(void *shmaddr);

    public static int shmctl(Shm shmid, int cmd, struct shmid_ds *buf);
}
