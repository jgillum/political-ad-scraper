
-- Table structure for table `OrgLookup`
DROP TABLE IF EXISTS `OrgLookup`;
CREATE TABLE `OrgLookup` (
  `pk` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `orgname` varchar(150) DEFAULT NULL,
  `orgtype` varchar(150) DEFAULT NULL,
  `party` varchar(10) DEFAULT NULL,
  `fecid` varchar(15) DEFAULT NULL,
  `youtubeid` varchar(20) NOT NULL,
  `active` tinyint(1) NOT NULL DEFAULT '1',
  PRIMARY KEY (`pk`),
  KEY `youtubeid` (`youtubeid`),
  KEY `orgname` (`orgname`),
  KEY `active` (`active`)
) ENGINE=InnoDB AUTO_INCREMENT=1 DEFAULT CHARSET=latin1;

-- Table structure for table `Videos`
DROP TABLE IF EXISTS `Videos`;
CREATE TABLE `Videos` (
  `pk` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `orgid` varchar(40) NOT NULL,
  `vidid` varchar(50) DEFAULT NULL,
  `title` varchar(200) DEFAULT NULL,
  `descr` mediumtext NOT NULL,
  `url` varchar(255) DEFAULT NULL,
  `localfile` varchar(40) NOT NULL,
  `inarchive` tinyint(1) NOT NULL DEFAULT '1',
  `protect_from_delete` tinyint(4) NOT NULL DEFAULT '0',
  `created` datetime DEFAULT NULL,
  `updated` datetime DEFAULT NULL,
  `record_modified` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`pk`),
  KEY `orgid` (`orgid`),
  KEY `vidid` (`vidid`),
  KEY `url` (`url`),
  KEY `created` (`created`),
  KEY `updated` (`updated`),
  KEY `record_modified` (`record_modified`),
  KEY `localfile` (`localfile`),
  KEY `protect_from_delete` (`protect_from_delete`)
) ENGINE=InnoDB AUTO_INCREMENT=1 DEFAULT CHARSET=latin1;
