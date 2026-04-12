{
  programs.git.settings = {
    sendemail = {
      smtpserver = "smtp.fastmail.com";
      smtpserverport = 465;
      smtpencryption = "ssl";
      smtpuser = "jw910731@fastmail.tw";
      from = "jw910731@gmail.com";
    };
  };

  programs.git.settings = {
    "credential \"smtp://jw910731%40fastmail.tw@smtp.fastmail.com:465\"" = {
      helper = "!f() { cat; echo password=$(op read 'op://Private/Fastmail Git Credential/credential' 2>/dev/null); }; f";
    };
  };
}
