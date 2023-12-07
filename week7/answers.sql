-- Create your tables, views, functions and procedures here!
CREATE SCHEMA destruction;
USE destruction;

CREATE TABLE players (
  player_id INT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
  first_name VARCHAR(30),
  last_name VARCHAR(30),
  email TEXT
);

CREATE TABLE characters (
  character_id INT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
  player_id INT UNSIGNED,
  name VARCHAR(30),
  -- Level *shouldn't* be negative, right?
  level INT UNSIGNED,
  CONSTRAINT characters_fk_players
    FOREIGN KEY (player_id)
    REFERENCES players (player_id)
      ON UPDATE CASCADE
      ON DELETE CASCADE
);

CREATE TABLE winners (
  character_id INT UNSIGNED PRIMARY KEY,
  name VARCHAR(30),
  CONSTRAINT winners_fk_characters
    FOREIGN KEY (character_id)
    REFERENCES characters (character_id)
      ON UPDATE CASCADE
      ON DELETE CASCADE
);

CREATE TABLE character_stats (
  character_id INT UNSIGNED PRIMARY KEY,
  health INT UNSIGNED,
  armor INT UNSIGNED,
  CONSTRAINT char_stars_fk_characters
    FOREIGN KEY (character_id)
    REFERENCES characters (character_id)
      ON UPDATE CASCADE
      ON DELETE CASCADE
);

CREATE TABLE teams (
  team_id INT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
  name VARCHAR(30)
);

CREATE TABLE team_members (
  team_member_id INT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
  team_id INT UNSIGNED,
  character_id INT UNSIGNED,
  CONSTRAINT team_members_fk_teams
    FOREIGN KEY (team_id)
    REFERENCES teams (team_id)
      ON UPDATE CASCADE
      ON DELETE CASCADE,
  CONSTRAINT team_members_fk_characters
    FOREIGN KEY (character_id)
    REFERENCES characters (character_id)
      ON UPDATE CASCADE
      ON DELETE CASCADE
);

CREATE TABLE items (
  item_id INT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
  name VARCHAR(30),
  -- Leaving armor signed because armor could potentially be a negative debuff.
  armor INT,
  damage INT UNSIGNED
);

CREATE TABLE inventory (
  inventory_id INT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
  character_id INT UNSIGNED,
  item_id INT UNSIGNED,
  CONSTRAINT inventory_fk_characters
    FOREIGN KEY (character_id)
    REFERENCES characters (character_id)
      ON UPDATE CASCADE
      ON DELETE CASCADE,
  CONSTRAINT inventory_fk_items
    FOREIGN KEY (item_id)
    REFERENCES items (item_id)
      ON UPDATE CASCADE
      ON DELETE CASCADE
);

CREATE TABLE equipped (
  equipped_id INT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
  character_id INT UNSIGNED,
  item_id INT UNSIGNED,
  CONSTRAINT equipped_fk_characters
    FOREIGN KEY (character_id)
    REFERENCES characters (character_id)
      ON UPDATE CASCADE
      ON DELETE CASCADE,
  CONSTRAINT equipped_fk_items
    FOREIGN KEY (item_id)
    REFERENCES items (item_id)
      ON UPDATE CASCADE
      ON DELETE CASCADE
);

CREATE OR REPLACE VIEW character_items AS
  SELECT 
    c.character_id AS character_id, 
    c.name AS character_name, 
    items.name AS item_name, 
    items.armor AS armor,
    items.damage AS damage
    FROM inventory
  		INNER JOIN characters c ON c.character_id = inventory.character_id
      INNER JOIN items ON items.item_id = inventory.item_id
        UNION SELECT 
    			c.character_id, 
    			c.name AS character_name, 
    			items.name AS item_name, 
    			items.armor AS armor,
    			items.damage AS damage
          FROM equipped
        		INNER JOIN characters c ON c.character_id = equipped.character_id
            INNER JOIN items ON items.item_id = equipped.item_id
            ORDER BY item_name;
    
CREATE OR REPLACE VIEW team_items AS
	SELECT
		t.team_id AS team_id, 
		t.name AS team_name, 
		items.name AS item_name, 
		items.armor AS armor,
		items.damage AS damage
		FROM inventory
			INNER JOIN characters c ON c.character_id = inventory.character_id
			INNER JOIN items ON items.item_id = inventory.item_id
			INNER JOIN team_members tm ON c.character_id = tm.character_id
			INNER JOIN teams t ON tm.team_id = t.team_id
	UNION SELECT 
		t.team_id AS team_id, 
		t.name AS team_name, 
		items.name AS item_name, 
		items.armor AS armor,
		items.damage AS damage
		FROM equipped
			INNER JOIN characters c ON c.character_id = equipped.character_id
			INNER JOIN items ON items.item_id = equipped.item_id
			INNER JOIN team_members tm ON c.character_id = tm.character_id
			INNER JOIN teams t ON tm.team_id = t.team_id
			GROUP BY items.item_id
			ORDER BY item_name;


