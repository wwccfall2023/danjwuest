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
-- Made health signed so it can be a negative value without breaking.
  health INT,
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
			ORDER BY item_name;


DELIMITER ;;
CREATE FUNCTION armor_total(character_id INT)
RETURNS INT UNSIGNED
READS SQL DATA
BEGIN
	DECLARE equipped_armor_sum INT;
    DECLARE armor_stat INT;
    SELECT 
		SUM(items.armor) INTO equipped_armor_sum
		FROM equipped e
			INNER JOIN items ON e.item_id = items.item_id
		WHERE 
			e.character_id = character_id
		GROUP BY e.character_id;
	SELECT armor INTO armor_stat FROM character_stats cs
		WHERE cs.character_id = character_id;
		RETURN equipped_armor_sum + armor_stat;
END;;
DELIMITER ;

DELIMITER ;;
-- I got a little stumped here, so I looked up ways to save data into individual variables.
-- Found this on stack overflow:
-- https://stackoverflow.com/questions/4823880/sql-server-select-into-variable
-- Then I looked at the CURSOR lesson again and realized I didn't need to do that, but
-- I thought I should include the link anyway.
CREATE PROCEDURE equip(selected_inventory_id INT)
	BEGIN
    DECLARE equipping_inventory_id INT;
    DECLARE equipping_character_id INT;
    DECLARE equipping_item_id INT;
    
	SELECT * INTO equipping_inventory_id, equipping_character_id, equipping_item_id
			FROM inventory i 
			WHERE i.inventory_id = selected_inventory_id;
            
	INSERT INTO 
		equipped (character_id, item_id) 
        VALUES
			(equipping_character_id, equipping_item_id);
	
    DELETE FROM inventory WHERE inventory_id = selected_inventory_id;
	END;;
DELIMITER ;


DELIMITER ;;
CREATE PROCEDURE unequip(selected_equipped_id INT)
	BEGIN
    DECLARE unequipping_equipped_id INT;
    DECLARE unequipping_character_id INT;
    DECLARE unequipping_item_id INT;
    
	SELECT * INTO unequipping_equipped_id, unequipping_character_id, unequipping_item_id
			FROM equipped 
			WHERE equipped.equipped_id = selected_equipped_id;
            
	INSERT INTO 
		inventory (character_id, item_id) 
        VALUES
			(unequipping_character_id, unequipping_item_id);
	
    DELETE FROM equipped WHERE equipped_id = selected_equipped_id;
	END;;
DELIMITER ;

DELIMITER ;;
CREATE PROCEDURE attack(id_of_character_being_attacked INT, id_of_equipped_item_used_for_attack INT)
	BEGIN
    DECLARE total_armor INT;
    DECLARE item_damage INT;
    DECLARE current_health INT;
    SELECT armor_total(id_of_character_being_attacked) INTO total_armor;
    
    SELECT i.damage INTO item_damage 
		FROM equipped e 
			INNER JOIN items i ON e.item_id = i.item_id
        WHERE e.item_id = id_of_equipped_item_used_for_attack;
    
    IF item_damage > total_armor THEN
		SELECT health INTO current_health FROM character_stats cs 
			WHERE cs.character_id = id_of_character_being_attacked;
		SET current_health = current_health - (item_damage - total_armor);
		UPDATE character_stats cs
			SET health = current_health
            WHERE cs.character_id = id_of_character_being_attacked;

            
        IF current_health <= 0 THEN
			DELETE FROM characters WHERE character_id = id_of_character_being_attacked;
        END IF;
    END IF;
    
    END;;
DELIMITER ;
