CREATE TABLE `pb_racing` (
  `id` int(11) NOT NULL,
  `name` text NOT NULL,
  `data` text NOT NULL,
  `laps` tinyint(1) NOT NULL,
  `creator` text NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_general_ci;

ALTER TABLE `pb_racing`
  ADD PRIMARY KEY (`id`);

ALTER TABLE `pb_racing`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;