DROP TABLE IF EXISTS `tles`;
CREATE TABLE `tles` (
    `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `norad_cat_no` SMALLINT UNSIGNED NOT NULL,
    `el_set_epoch_unix` INT UNSIGNED DEFAULT NULL,
    `el_set_line_0` VARCHAR(24) NOT NULL,
    `el_set_line_1` VARCHAR(69) NOT NULL,
    `el_set_line_2` VARCHAR(69) NOT NULL,
    `date_created` INT UNSIGNED DEFAULT UNIX_TIMESTAMP(),
    PRIMARY KEY  (`id`),
    UNIQUE KEY `idx_ncn_epoch` (`norad_cat_no`, `el_set_epoch_unix`)
) ENGINE=InnoDB CHARSET=utf8;
