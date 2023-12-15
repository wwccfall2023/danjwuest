-- Create your tables, views, functions and procedures here!
CREATE SCHEMA social;
USE social;

CREATE TABLE users (
	user_id INT UNSIGNED NOT NULL PRIMARY KEY AUTO_INCREMENT,
	first_name VARCHAR(30) NOT NULL,
	last_name VARCHAR(30) NOT NULL,
	email TEXT NOT NULL,
	-- Found current timestamp here:
	-- https://www.w3schools.com/sql/func_sqlserver_current_timestamp.asp
	created_on DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE sessions (
  session_id INT UNSIGNED NOT NULL PRIMARY KEY AUTO_INCREMENT,
  user_id INT UNSIGNED NOT NULL,
  created_on DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_on DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT sessions_fk_users
    FOREIGN KEY (user_id)
    REFERENCES users (user_id)
      ON UPDATE CASCADE
      ON DELETE CASCADE
);

CREATE TABLE friends (
	user_friend_id INT UNSIGNED NOT NULL PRIMARY KEY AUTO_INCREMENT,
	user_id INT UNSIGNED NOT NULL,
	friend_id INT UNSIGNED NOT NULL,
	CONSTRAINT friends_user_fk_users
		FOREIGN KEY (user_id)
		REFERENCES users (user_id)
			ON UPDATE CASCADE
			ON DELETE CASCADE,
	CONSTRAINT friends_friend_fk_users
		FOREIGN KEY (friend_id)
		REFERENCES users (user_id)
			ON UPDATE CASCADE
			ON DELETE CASCADE
);

CREATE TABLE posts (
	post_id INT UNSIGNED NOT NULL PRIMARY KEY AUTO_INCREMENT,
	user_id INT UNSIGNED NOT NULL,
	created_on DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
	updated_on DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
	content TEXT NOT NULL,
    CONSTRAINT posts_fk_users
		FOREIGN KEY (user_id)
		REFERENCES users (user_id)
			ON UPDATE CASCADE
			ON DELETE CASCADE
);

CREATE TABLE notifications (
	notification_id INT UNSIGNED NOT NULL PRIMARY KEY AUTO_INCREMENT,
	user_id INT UNSIGNED NOT NULL,
    post_id INT UNSIGNED NOT NULL,
    CONSTRAINT notifications_fk_users
		FOREIGN KEY (user_id)
		REFERENCES users (user_id)
			ON UPDATE CASCADE
			ON DELETE CASCADE,
	CONSTRAINT notifications_fk_posts
		FOREIGN KEY (post_id)
		REFERENCES posts (post_id)
			ON UPDATE CASCADE
			ON DELETE CASCADE
);