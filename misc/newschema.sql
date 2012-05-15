SET character_set_client = utf8;
DROP TABLE IF EXISTS vacation_notification;
DROP TABLE IF EXISTS vacation;
DROP TABLE IF EXISTS quota2;
DROP TABLE IF EXISTS quota;
DROP TABLE IF EXISTS mailbox;
DROP TABLE IF EXISTS log;
DROP TABLE IF EXISTS fetchmail;
DROP TABLE IF EXISTS domain_admins;
DROP TABLE IF EXISTS alias;
DROP TABLE IF EXISTS alias_domain;
DROP TABLE IF EXISTS domain;
DROP TABLE IF EXISTS admin;
DROP TABLE IF EXISTS config;

CREATE TABLE config (
  name varchar(255) NOT NULL DEFAULT '',
  value varchar(255) NULL,
  PRIMARY KEY (name)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='Ashafix settings';

CREATE TABLE admin (
  username varchar(255) NOT NULL,
  password varchar(255) NOT NULL,
  created datetime NOT NULL DEFAULT '0000-00-00 00:00:00',
  modified datetime NOT NULL DEFAULT '0000-00-00 00:00:00',
  active tinyint NOT NULL DEFAULT '1',
  PRIMARY KEY (username)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='Ashafix Virtual Admins';

CREATE TABLE domain (
  domain varchar(255) NOT NULL,
  description varchar(255) CHARACTER SET utf8 NOT NULL,
  aliases integer NOT NULL DEFAULT '0',
  mailboxes integer NOT NULL DEFAULT '0',
  maxquota BIGINT NOT NULL DEFAULT '0',
  quota BIGINT NOT NULL DEFAULT '0',
  transport varchar(255) NOT NULL,
  backupmx tinyint(1) NOT NULL DEFAULT '0',
  created datetime NOT NULL DEFAULT '0000-00-00 00:00:00',
  modified datetime NOT NULL DEFAULT '0000-00-00 00:00:00',
  active tinyint(1) NOT NULL DEFAULT '1',
  PRIMARY KEY (domain)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='Ashafix Virtual Domains';

CREATE TABLE alias_domain (
  alias_domain varchar(255) NOT NULL,
  target_domain varchar(255) NOT NULL,
  created datetime NOT NULL DEFAULT '0000-00-00 00:00:00',
  modified datetime NOT NULL DEFAULT '0000-00-00 00:00:00',
  active tinyint(1) NOT NULL DEFAULT '1',
  PRIMARY KEY (alias_domain),
  KEY active (active),
  FOREIGN KEY target_domain (target_domain) REFERENCES domain (domain) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='Ashafix Domain Aliases';

CREATE TABLE alias (
  address varchar(255) NOT NULL,
  goto text NOT NULL,
  domain varchar(255) NOT NULL,
  created datetime NOT NULL DEFAULT '0000-00-00 00:00:00',
  modified datetime NOT NULL DEFAULT '0000-00-00 00:00:00',
  active tinyint(1) NOT NULL DEFAULT '1',
  PRIMARY KEY (address),
  FOREIGN KEY domain (domain) REFERENCES domain (domain) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='Ashafix Virtual Aliases';

CREATE TABLE domain_admins (
  username varchar(255) NOT NULL,
  domain varchar(255) NOT NULL,
  created datetime NOT NULL DEFAULT '0000-00-00 00:00:00',
  active tinyint NOT NULL DEFAULT '1',
  PRIMARY KEY username (username),
  FOREIGN KEY domain (domain) REFERENCES domain (domain) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='Ashafix Domain Admins';

CREATE TABLE fetchmail (
  id integer unsigned NOT NULL AUTO_INCREMENT,
  mailbox varchar(255) NOT NULL, -- TODO foreign key?
  src_server varchar(255) NOT NULL,
  src_auth enum('password','kerberos_v5','kerberos','kerberos_v4','gssapi','cram-md5','otp','ntlm','msn','ssh','any') DEFAULT NULL,
  src_user varchar(255) NOT NULL,
  src_password varchar(255) NOT NULL,
  src_folder varchar(255) NOT NULL,
  poll_time integer unsigned NOT NULL DEFAULT '10',
  fetchall tinyint(1) unsigned NOT NULL DEFAULT '0',
  keep tinyint(1) unsigned NOT NULL DEFAULT '0',
  protocol enum('POP3','IMAP','POP2','ETRN','AUTO') DEFAULT NULL,
  usessl tinyint(1) unsigned NOT NULL DEFAULT '0',
  extra_options text,
  returned_text text,
  mda varchar(255) NOT NULL,
  date timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

CREATE TABLE log (
  timestamp datetime NOT NULL DEFAULT '0000-00-00 00:00:00',
  username varchar(255) NOT NULL,
  domain varchar(255) NOT NULL,
  action varchar(255) NOT NULL,
  data text NOT NULL,
  KEY timestamp (timestamp)
  -- Suppose we want to keep log entries even if corresponding domains disappear
  -- FOREIGN KEY domain (domain) REFERENCES domain (domain) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='Ashafix Log';

CREATE TABLE mailbox (
  username varchar(255) NOT NULL,
  password varchar(255) NOT NULL,
  name varchar(255) NOT NULL,
  maildir varchar(255) NOT NULL,
  quota BIGINT NOT NULL DEFAULT '0',
  local_part varchar(255) NOT NULL,
  domain varchar(255) NOT NULL,
  created datetime NOT NULL DEFAULT '0000-00-00 00:00:00',
  modified datetime NOT NULL DEFAULT '0000-00-00 00:00:00',
  active tinyint(1) NOT NULL DEFAULT '1',
  PRIMARY KEY (username),
  FOREIGN KEY domain (domain) REFERENCES domain (domain) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='Ashafix Virtual Mailboxes';

CREATE TABLE quota (
  username varchar(255) NOT NULL,
  path varchar(100) NOT NULL,
  current BIGINT DEFAULT NULL,
  PRIMARY KEY (username,path),
  FOREIGN KEY username (username) REFERENCES mailbox (username) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

CREATE TABLE quota2 (
  username varchar(100) NOT NULL,
  bytes BIGINT NOT NULL DEFAULT '0',
  messages integer NOT NULL DEFAULT '0',
  PRIMARY KEY (username),
  FOREIGN KEY username (username) REFERENCES mailbox (username) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

CREATE TABLE vacation (
  email varchar(255) NOT NULL,
  subject varchar(255) CHARACTER SET utf8 NOT NULL,
  body text CHARACTER SET utf8 NOT NULL,
  cache text NOT NULL,
  domain varchar(255) NOT NULL,
  created datetime NOT NULL DEFAULT '0000-00-00 00:00:00',
  active tinyint(1) NOT NULL DEFAULT '1',
  PRIMARY KEY (email),
  FOREIGN KEY domain (domain) REFERENCES domain (domain) ON DELETE CASCADE
  -- TODO  FOREIGN KEY email (email) REFERENCES mailbox (username) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='Ashafix Virtual Vacation';

CREATE TABLE vacation_notification (
  on_vacation varchar(255) NOT NULL,
  notified varchar(255) NOT NULL,
  notified_at timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (on_vacation,notified),
  FOREIGN KEY on_vacation (on_vacation) REFERENCES vacation (email) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='Ashafix Virtual Vacation Notifications';
