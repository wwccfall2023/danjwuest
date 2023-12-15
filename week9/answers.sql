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

DELIMITER ;;
CREATE TRIGGER session_update_time
	AFTER UPDATE ON sessions
	FOR EACH ROW
BEGIN
	UPDATE sessions SET updated_on = CURRENT_TIMESTAMP WHERE session_id = NEW.session_id;
END;;
DELIMITER ;

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

DELIMITER ;;
CREATE TRIGGER post_update_time
	AFTER UPDATE ON posts
	FOR EACH ROW
BEGIN
	UPDATE posts SET updated_on = CURRENT_TIMESTAMP WHERE post_id = NEW.post_id;
END;;
DELIMITER ;

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

DELIMITER ;;
CREATE TRIGGER notification_new_user
	AFTER INSERT ON users
	FOR EACH ROW
BEGIN
	DECLARE join_post_id INT;
    DECLARE current_notification_user_id INT;
    DECLARE row_not_found TINYINT DEFAULT FALSE;
    
    DECLARE users_cursor CURSOR FOR
		SELECT user_id
			FROM users;
	
    DECLARE CONTINUE HANDLER FOR NOT FOUND
		SET row_not_found = TRUE;
	
	-- I looked up how to put data into strings here:
	-- https://stackoverflow.com/questions/17754188/how-to-concatenate-variables-into-sql-strings
	-- Then instead used normal concatenation instead:
	-- https://www.w3schools.com/sql/func_sqlserver_concat.asp
	INSERT INTO posts (user_id, content) VALUES (NEW.user_id, CONCAT(NEW.first_name,' ',NEW.last_name, ' just joined!'));
    
    -- Found a way to get the ID of the last insert's auto increment:
    -- https://docs.oracle.com/cd/E17952_01/connector-odbc-en/connector-odbc-usagenotes-functionality-last-insert-id.html#:~:text=To%20obtain%20the%20value%20immediately,obtain%20the%20auto%2Dincrement%20value.
    SET join_post_id = LAST_INSERT_ID();
    
    OPEN users_cursor;
    user_loop : LOOP
		FETCH users_cursor INTO current_notification_user_id;
        
        IF row_not_found THEN
        
			LEAVE user_loop;
		END IF;
        
        IF current_notification_user_id != NEW.user_id THEN
			-- Makes sure the user doesn't get a notification of their own joining.
			INSERT INTO notifications (user_id, post_id) VALUES (current_notification_user_id, join_post_id);
		END IF;
	END LOOP user_loop;
END;;
DELIMITER ;

CREATE OR REPLACE VIEW notification_posts AS
	SELECT 
		n.user_id AS user_id, 
		u.first_name AS first_name,
        u.last_name AS last_name,
        p.post_id AS post_id,
        p.content AS content
        FROM notifications n
			INNER JOIN posts p ON n.post_id = p.post_id
            INNER JOIN users u ON p.user_id = u.user_id
			ORDER BY n.user_id;

DELIMITER ;;
CREATE PROCEDURE add_post(user_id INT, content TEXT)
	BEGIN
		DECLARE current_friend_id INT;
        DECLARE new_post_id INT;
		DECLARE row_not_found TINYINT DEFAULT FALSE;
        
		DECLARE friends_cursor CURSOR FOR
			SELECT friend_id
				FROM friends
					WHERE user_id = NEW.user_id;
	
		DECLARE CONTINUE HANDLER FOR NOT FOUND
			SET row_not_found = TRUE;
            
		INSERT INTO posts (user_id, content)
			VALUES (user_id, content);
            
		SET new_post_id = LAST_INSERT_ID();
        
            
		OPEN friends_cursor;
			friend_loop : LOOP
				FETCH friends_cursor INTO current_friend_id;
				
				IF row_not_found THEN
				
					LEAVE friend_loop;
				END IF;
				
				INSERT INTO notifications (user_id, post_id) VALUES (current_friend_id, new_post_id);
			
			END LOOP friend_loop;
		CLOSE friends_cursor;
        
        
	END;;
DELIMITER ;
