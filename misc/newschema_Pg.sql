DROP TABLE vacation_notification;
DROP TABLE vacation;
DROP TABLE quota2;
DROP TABLE quota;
DROP TABLE mailbox;
DROP TABLE log;
DROP TABLE domain_admins;
DROP TABLE alias;
DROP TABLE alias_domain;
DROP TABLE domain;
DROP TABLE admin;
DROP TABLE config;

CREATE TABLE config (
  name varchar(255) NOT NULL DEFAULT '',
  value varchar(255) NULL,
  PRIMARY KEY (name)
) COMMENT='Ashafix settings';

CREATE TABLE admin (
  username varchar(255) NOT NULL,
  password varchar(255) NOT NULL,
  created datetime NOT NULL DEFAULT '0000-00-00 00:00:00',
  modified datetime NOT NULL DEFAULT '0000-00-00 00:00:00',
  active boolean NOT NULL DEFAULT 't',
  PRIMARY KEY (username)
) COMMENT='Ashafix Virtual Admins';

CREATE TABLE domain (
  domain varchar(255) NOT NULL,
  description varchar(255) CHARACTER SET utf8 NOT NULL,
  aliases integer NOT NULL DEFAULT '0',
  mailboxes integer NOT NULL DEFAULT '0',
  maxquota BIGINT NOT NULL DEFAULT '0',
  quota BIGINT NOT NULL DEFAULT '0',
  transport varchar(255) NOT NULL,
  backupmx boolean NOT NULL DEFAULT '0',
  created datetime NOT NULL DEFAULT '0000-00-00 00:00:00',
  modified datetime NOT NULL DEFAULT '0000-00-00 00:00:00',
  active boolean NOT NULL DEFAULT 't',
  PRIMARY KEY (domain)
) COMMENT='Ashafix Virtual Domains';

CREATE TABLE alias_domain (
  alias_domain varchar(255) NOT NULL,
  target_domain varchar(255) NOT NULL,
  created datetime NOT NULL DEFAULT '0000-00-00 00:00:00',
  modified datetime NOT NULL DEFAULT '0000-00-00 00:00:00',
  active boolean NOT NULL DEFAULT 't',
  PRIMARY KEY (alias_domain),
  KEY active (active),
  FOREIGN KEY target_domain (target_domain) REFERENCES domain (domain) ON DELETE CASCADE
) COMMENT='Ashafix Domain Aliases';

CREATE TABLE alias (
  address varchar(255) NOT NULL,
  goto text NOT NULL,
  domain varchar(255) NOT NULL,
  created datetime NOT NULL DEFAULT '0000-00-00 00:00:00',
  modified datetime NOT NULL DEFAULT '0000-00-00 00:00:00',
  active boolean NOT NULL DEFAULT 't',
  PRIMARY KEY (address),
  FOREIGN KEY domain (domain) REFERENCES domain (domain) ON DELETE CASCADE
) COMMENT='Ashafix Virtual Aliases';

CREATE TABLE domain_admins (
  username varchar(255) NOT NULL,
  domain varchar(255) NOT NULL,
  created datetime NOT NULL DEFAULT '0000-00-00 00:00:00',
  active boolean NOT NULL DEFAULT 't',
  PRIMARY KEY username_domain (username,domain),
  FOREIGN KEY domain (domain) REFERENCES domain (domain) ON DELETE CASCADE
) COMMENT='Ashafix Domain Admins';

CREATE TABLE log (
  timestamp datetime NOT NULL DEFAULT '0000-00-00 00:00:00',
  username varchar(255) NOT NULL,
  domain varchar(255) NOT NULL,
  action varchar(255) NOT NULL,
  data text NOT NULL,
  KEY timestamp (timestamp)
  -- Suppose we want to keep log entries even if corresponding domains disappear
  -- FOREIGN KEY domain (domain) REFERENCES domain (domain) ON DELETE CASCADE
) COMMENT='Ashafix Log';

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
  active boolean NOT NULL DEFAULT 't',
  PRIMARY KEY (username),
  FOREIGN KEY domain (domain) REFERENCES domain (domain) ON DELETE CASCADE
) COMMENT='Ashafix Virtual Mailboxes';

CREATE TABLE quota (
  username varchar(255) NOT NULL,
  path varchar(100) NOT NULL,
  current BIGINT DEFAULT NULL,
  PRIMARY KEY (username,path),
  FOREIGN KEY username (username) REFERENCES mailbox (username) ON DELETE CASCADE
) COMMENT='Ashafix old format quotas';

CREATE TABLE quota2 (
  username varchar(100) NOT NULL,
  bytes BIGINT NOT NULL DEFAULT '0',
  messages integer NOT NULL DEFAULT '0',
  PRIMARY KEY (username),
  FOREIGN KEY username (username) REFERENCES mailbox (username) ON DELETE CASCADE
) COMMENT='Ashafix new format quotas';

CREATE TABLE vacation (
  email varchar(255) NOT NULL,
  subject varchar(255) CHARACTER SET utf8 NOT NULL,
  body text CHARACTER SET utf8 NOT NULL,
  cache text NOT NULL,
  domain varchar(255) NOT NULL,
  created datetime NOT NULL DEFAULT '0000-00-00 00:00:00',
  active boolean NOT NULL DEFAULT 't',
  PRIMARY KEY (email),
  FOREIGN KEY domain (domain) REFERENCES domain (domain) ON DELETE CASCADE
  -- TODO  FOREIGN KEY email (email) REFERENCES mailbox (username) ON DELETE CASCADE
) COMMENT='Ashafix Virtual Vacation';

CREATE TABLE vacation_notification (
  on_vacation varchar(255) NOT NULL,
  notified varchar(255) NOT NULL,
  notified_at timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (on_vacation,notified),
  FOREIGN KEY on_vacation (on_vacation) REFERENCES vacation (email) ON DELETE CASCADE
) COMMENT='Ashafix Virtual Vacation Notifications';
