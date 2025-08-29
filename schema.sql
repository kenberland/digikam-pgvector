mysqldump: [Warning] Using a password on the command line interface can be insecure.
-- MySQL dump 10.13  Distrib 9.3.0, for Linux (x86_64)
--
-- Host: 127.0.0.1    Database: digikam
-- ------------------------------------------------------
-- Server version	9.3.0

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!50503 SET NAMES utf8mb4 */;
/*!40103 SET @OLD_TIME_ZONE=@@TIME_ZONE */;
/*!40103 SET TIME_ZONE='+00:00' */;
/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;

--
-- Current Database: `digikam`
--

CREATE DATABASE /*!32312 IF NOT EXISTS*/ `digikam` /*!40100 DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci */ /*!80016 DEFAULT ENCRYPTION='N' */;

USE `digikam`;

--
-- Table structure for table `AlbumRoots`
--

DROP TABLE IF EXISTS `AlbumRoots`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `AlbumRoots` (
  `id` int NOT NULL AUTO_INCREMENT,
  `label` longtext CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci,
  `status` int NOT NULL,
  `type` int NOT NULL,
  `identifier` longtext CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci,
  `specificPath` longtext CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci,
  `caseSensitivity` int DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `identifier` (`identifier`(127),`specificPath`(128))
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `Albums`
--

DROP TABLE IF EXISTS `Albums`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `Albums` (
  `id` int NOT NULL AUTO_INCREMENT,
  `albumRoot` int NOT NULL,
  `relativePath` longtext CHARACTER SET utf8mb3 COLLATE utf8mb3_bin NOT NULL,
  `date` date DEFAULT NULL,
  `caption` longtext CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci,
  `collection` longtext CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci,
  `icon` bigint DEFAULT NULL,
  `modificationDate` datetime DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `albumRoot` (`albumRoot`,`relativePath`(255)),
  KEY `Albums_Images` (`icon`),
  CONSTRAINT `Albums_AlbumRoots` FOREIGN KEY (`albumRoot`) REFERENCES `AlbumRoots` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `Albums_Images` FOREIGN KEY (`icon`) REFERENCES `Images` (`id`) ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=379 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `CustomIdentifiers`
--

DROP TABLE IF EXISTS `CustomIdentifiers`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `CustomIdentifiers` (
  `identifier` longtext CHARACTER SET utf8mb3 COLLATE utf8mb3_bin,
  `thumbId` bigint DEFAULT NULL,
  UNIQUE KEY `identifier` (`identifier`(255)),
  KEY `id_customIdentifiers` (`thumbId`),
  CONSTRAINT `CustomIdentifiers_Thumbnails` FOREIGN KEY (`thumbId`) REFERENCES `Thumbnails` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `DownloadHistory`
--

DROP TABLE IF EXISTS `DownloadHistory`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `DownloadHistory` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `identifier` longtext CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci,
  `filename` longtext CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci,
  `filesize` bigint DEFAULT NULL,
  `filedate` datetime DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `identifier` (`identifier`(164),`filename`(165),`filesize`,`filedate`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `FaceMatrices`
--

DROP TABLE IF EXISTS `FaceMatrices`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `FaceMatrices` (
  `id` int NOT NULL AUTO_INCREMENT,
  `identity` int NOT NULL,
  `removeHash` longtext CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci NOT NULL,
  `embedding` blob NOT NULL,
  PRIMARY KEY (`id`),
  KEY `FaceEmbedding_Identities` (`identity`),
  CONSTRAINT `FaceEmbedding_Identities` FOREIGN KEY (`identity`) REFERENCES `Identities` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `FaceSettings`
--

DROP TABLE IF EXISTS `FaceSettings`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `FaceSettings` (
  `keyword` longtext CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci NOT NULL,
  `value` longtext CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci,
  UNIQUE KEY `keyword` (`keyword`(255))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `FilePaths`
--

DROP TABLE IF EXISTS `FilePaths`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `FilePaths` (
  `path` longtext CHARACTER SET utf8mb3 COLLATE utf8mb3_bin,
  `thumbId` bigint DEFAULT NULL,
  UNIQUE KEY `path` (`path`(255)),
  KEY `id_filePaths` (`thumbId`),
  CONSTRAINT `FilePaths_Thumbnails` FOREIGN KEY (`thumbId`) REFERENCES `Thumbnails` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `Identities`
--

DROP TABLE IF EXISTS `Identities`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `Identities` (
  `id` int NOT NULL AUTO_INCREMENT,
  `type` int DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `IdentityAttributes`
--

DROP TABLE IF EXISTS `IdentityAttributes`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `IdentityAttributes` (
  `id` int DEFAULT NULL,
  `type` int DEFAULT NULL,
  `attribute` longtext CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci,
  `value` longtext CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci,
  KEY `identityattributes_index` (`id`),
  CONSTRAINT `IdentityAttributes_Identities` FOREIGN KEY (`id`) REFERENCES `Identities` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `ImageComments`
--

DROP TABLE IF EXISTS `ImageComments`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `ImageComments` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `imageid` bigint DEFAULT NULL,
  `type` int DEFAULT NULL,
  `language` varchar(128) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL,
  `author` longtext CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci,
  `date` datetime DEFAULT NULL,
  `comment` longtext CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci,
  PRIMARY KEY (`id`),
  UNIQUE KEY `imageid` (`imageid`,`type`,`language`,`author`(202)),
  KEY `comments_imageid_index` (`imageid`),
  CONSTRAINT `ImageComments_Images` FOREIGN KEY (`imageid`) REFERENCES `Images` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=70158 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `ImageCopyright`
--

DROP TABLE IF EXISTS `ImageCopyright`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `ImageCopyright` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `imageid` bigint DEFAULT NULL,
  `property` longtext CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci,
  `value` longtext CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci,
  `extraValue` longtext CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci,
  PRIMARY KEY (`id`),
  UNIQUE KEY `imageid` (`imageid`,`property`(110),`value`(111),`extraValue`(111)),
  KEY `copyright_imageid_index` (`imageid`),
  CONSTRAINT `ImageCopyright_Images` FOREIGN KEY (`imageid`) REFERENCES `Images` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=6587 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `ImageHaarMatrix`
--

DROP TABLE IF EXISTS `ImageHaarMatrix`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `ImageHaarMatrix` (
  `imageid` bigint NOT NULL,
  `modificationDate` datetime DEFAULT NULL,
  `uniqueHash` longtext CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci,
  `matrix` longblob,
  PRIMARY KEY (`imageid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `ImageHistory`
--

DROP TABLE IF EXISTS `ImageHistory`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `ImageHistory` (
  `imageid` bigint NOT NULL,
  `uuid` varchar(128) DEFAULT NULL,
  `history` longtext CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci,
  PRIMARY KEY (`imageid`),
  KEY `uuid_index` (`uuid`),
  CONSTRAINT `ImageHistory_Images` FOREIGN KEY (`imageid`) REFERENCES `Images` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `ImageInformation`
--

DROP TABLE IF EXISTS `ImageInformation`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `ImageInformation` (
  `imageid` bigint NOT NULL,
  `rating` int DEFAULT NULL,
  `creationDate` datetime DEFAULT NULL,
  `digitizationDate` datetime DEFAULT NULL,
  `orientation` int DEFAULT NULL,
  `width` int DEFAULT NULL,
  `height` int DEFAULT NULL,
  `format` longtext CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci,
  `colorDepth` int DEFAULT NULL,
  `colorModel` int DEFAULT NULL,
  PRIMARY KEY (`imageid`),
  KEY `creationdate_index` (`creationDate`),
  CONSTRAINT `ImageInformation_Images` FOREIGN KEY (`imageid`) REFERENCES `Images` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `ImageMetadata`
--

DROP TABLE IF EXISTS `ImageMetadata`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `ImageMetadata` (
  `imageid` bigint NOT NULL,
  `make` longtext CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci,
  `model` longtext CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci,
  `lens` longtext CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci,
  `aperture` double DEFAULT NULL,
  `focalLength` double DEFAULT NULL,
  `focalLength35` double DEFAULT NULL,
  `exposureTime` double DEFAULT NULL,
  `exposureProgram` int DEFAULT NULL,
  `exposureMode` int DEFAULT NULL,
  `sensitivity` int DEFAULT NULL,
  `flash` int DEFAULT NULL,
  `whiteBalance` int DEFAULT NULL,
  `whiteBalanceColorTemperature` int DEFAULT NULL,
  `meteringMode` int DEFAULT NULL,
  `subjectDistance` double DEFAULT NULL,
  `subjectDistanceCategory` int DEFAULT NULL,
  PRIMARY KEY (`imageid`),
  CONSTRAINT `ImageMetadata_Images` FOREIGN KEY (`imageid`) REFERENCES `Images` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `ImagePositions`
--

DROP TABLE IF EXISTS `ImagePositions`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `ImagePositions` (
  `imageid` bigint NOT NULL,
  `latitude` longtext CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci,
  `latitudeNumber` double DEFAULT NULL,
  `longitude` longtext CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci,
  `longitudeNumber` double DEFAULT NULL,
  `altitude` double DEFAULT NULL,
  `orientation` double DEFAULT NULL,
  `tilt` double DEFAULT NULL,
  `roll` double DEFAULT NULL,
  `accuracy` double DEFAULT NULL,
  `description` longtext CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci,
  PRIMARY KEY (`imageid`),
  CONSTRAINT `ImagePositions_Images` FOREIGN KEY (`imageid`) REFERENCES `Images` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `ImageProperties`
--

DROP TABLE IF EXISTS `ImageProperties`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `ImageProperties` (
  `imageid` bigint NOT NULL,
  `property` longtext CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci NOT NULL,
  `value` longtext CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci NOT NULL,
  UNIQUE KEY `imageid` (`imageid`,`property`(255)),
  CONSTRAINT `ImageProperties_Images` FOREIGN KEY (`imageid`) REFERENCES `Images` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `ImageRelations`
--

DROP TABLE IF EXISTS `ImageRelations`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `ImageRelations` (
  `subject` bigint DEFAULT NULL,
  `object` bigint DEFAULT NULL,
  `type` int DEFAULT NULL,
  UNIQUE KEY `subject` (`subject`,`object`,`type`),
  KEY `subject_relations_index` (`subject`),
  KEY `object_relations_index` (`object`),
  CONSTRAINT `ImageRelations_ImagesO` FOREIGN KEY (`object`) REFERENCES `Images` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `ImageRelations_ImagesS` FOREIGN KEY (`subject`) REFERENCES `Images` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `ImageSimilarity`
--

DROP TABLE IF EXISTS `ImageSimilarity`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `ImageSimilarity` (
  `imageid1` bigint NOT NULL,
  `imageid2` bigint NOT NULL,
  `algorithm` int DEFAULT NULL,
  `value` double DEFAULT NULL,
  UNIQUE KEY `Similar` (`imageid1`,`imageid2`,`algorithm`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `ImageTagProperties`
--

DROP TABLE IF EXISTS `ImageTagProperties`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `ImageTagProperties` (
  `imageid` bigint DEFAULT NULL,
  `tagid` int DEFAULT NULL,
  `property` text CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci,
  `value` longtext CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci,
  KEY `imagetagproperties_index` (`imageid`,`tagid`),
  KEY `imagetagproperties_imageid_index` (`imageid`),
  KEY `imagetagproperties_tagid_index` (`tagid`),
  CONSTRAINT `ImageTagProperties_Images` FOREIGN KEY (`imageid`) REFERENCES `Images` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `ImageTagProperties_Tags` FOREIGN KEY (`tagid`) REFERENCES `Tags` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `ImageTags`
--

DROP TABLE IF EXISTS `ImageTags`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `ImageTags` (
  `imageid` bigint NOT NULL,
  `tagid` int NOT NULL,
  UNIQUE KEY `imageid` (`imageid`,`tagid`),
  KEY `tag_index` (`tagid`),
  KEY `tag_id_index` (`imageid`),
  CONSTRAINT `ImageTags_Images` FOREIGN KEY (`imageid`) REFERENCES `Images` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `ImageTags_Tags` FOREIGN KEY (`tagid`) REFERENCES `Tags` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `Images`
--

DROP TABLE IF EXISTS `Images`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `Images` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `album` int DEFAULT NULL,
  `name` longtext CHARACTER SET utf8mb3 COLLATE utf8mb3_bin NOT NULL,
  `status` int NOT NULL,
  `category` int NOT NULL,
  `modificationDate` datetime DEFAULT NULL,
  `fileSize` bigint DEFAULT NULL,
  `uniqueHash` varchar(128) DEFAULT NULL,
  `manualOrder` bigint DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `album` (`album`,`name`(255)),
  KEY `dir_index` (`album`),
  KEY `hash_index` (`uniqueHash`),
  KEY `image_name_index` (`name`(255)),
  CONSTRAINT `Images_Albums` FOREIGN KEY (`album`) REFERENCES `Albums` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=278670 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `Searches`
--

DROP TABLE IF EXISTS `Searches`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `Searches` (
  `id` int NOT NULL AUTO_INCREMENT,
  `type` int DEFAULT NULL,
  `name` longtext CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci NOT NULL,
  `query` longtext CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=146 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `Settings`
--

DROP TABLE IF EXISTS `Settings`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `Settings` (
  `keyword` longtext CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci NOT NULL,
  `value` longtext CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci,
  UNIQUE KEY `keyword` (`keyword`(255))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `SimilaritySettings`
--

DROP TABLE IF EXISTS `SimilaritySettings`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `SimilaritySettings` (
  `keyword` longtext CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci NOT NULL,
  `value` longtext CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci,
  UNIQUE KEY `keyword` (`keyword`(255))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `TagProperties`
--

DROP TABLE IF EXISTS `TagProperties`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `TagProperties` (
  `tagid` int DEFAULT NULL,
  `property` text CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci,
  `value` longtext CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci,
  KEY `tagproperties_index` (`tagid`),
  CONSTRAINT `TagProperties_Tags` FOREIGN KEY (`tagid`) REFERENCES `Tags` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `Tags`
--

DROP TABLE IF EXISTS `Tags`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `Tags` (
  `id` int NOT NULL AUTO_INCREMENT,
  `pid` int DEFAULT NULL,
  `name` longtext CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci NOT NULL,
  `icon` bigint DEFAULT NULL,
  `iconkde` longtext CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci,
  PRIMARY KEY (`id`),
  UNIQUE KEY `pid` (`pid`,`name`(100)),
  KEY `Tags_Images` (`icon`),
  CONSTRAINT `Tags_Images` FOREIGN KEY (`icon`) REFERENCES `Images` (`id`) ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=373 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_0900_ai_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
/*!50003 CREATE*/ /*!50017 DEFINER=`root`@`%`*/ /*!50003 TRIGGER `insert_tagstree` AFTER INSERT ON `Tags` FOR EACH ROW INSERT INTO TagsTree SELECT NEW.id, NEW.pid
                     UNION SELECT NEW.id, pid FROM TagsTree WHERE id = NEW.pid */;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_0900_ai_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
/*!50003 CREATE*/ /*!50017 DEFINER=`root`@`%`*/ /*!50003 TRIGGER `move_tagstree` AFTER UPDATE ON `Tags` FOR EACH ROW BEGIN
                        IF (NEW.pid != OLD.pid) THEN
                            DELETE FROM TagsTree WHERE ((id = OLD.id) OR id IN (SELECT id FROM
                              (SELECT id FROM TagsTree WHERE pid = OLD.id) AS tmpTree1))
                             AND pid IN (SELECT pid FROM
                              (SELECT pid FROM TagsTree WHERE id = OLD.id) AS tmpTree2);
                            INSERT INTO TagsTree SELECT NEW.id, NEW.pid
                             UNION SELECT NEW.id, pid FROM TagsTree
                              WHERE id = NEW.pid
                             UNION SELECT id, NEW.pid FROM TagsTree
                              WHERE pid = NEW.id
                             UNION SELECT A.id, B.pid FROM TagsTree A, TagsTree B
                              WHERE A.pid = NEW.id AND B.id = NEW.pid;
                        END IF;
                    END */;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_0900_ai_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
/*!50003 CREATE*/ /*!50017 DEFINER=`root`@`%`*/ /*!50003 TRIGGER `delete_tagstree` AFTER DELETE ON `Tags` FOR EACH ROW BEGIN
                        DELETE FROM TagsTree WHERE id IN (SELECT id FROM
                          (SELECT id FROM TagsTree WHERE pid = OLD.id) AS tmpTree1);
                        DELETE FROM TagsTree WHERE id = OLD.id;
                    END */;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;

--
-- Table structure for table `TagsTree`
--

DROP TABLE IF EXISTS `TagsTree`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `TagsTree` (
  `id` int NOT NULL,
  `pid` int NOT NULL,
  UNIQUE KEY `id` (`id`,`pid`),
  KEY `tagstree_id_index` (`id`),
  KEY `tagstree_pid_index` (`pid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `ThumbSettings`
--

DROP TABLE IF EXISTS `ThumbSettings`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `ThumbSettings` (
  `keyword` longtext CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci NOT NULL,
  `value` longtext CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci,
  UNIQUE KEY `keyword` (`keyword`(255))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `Thumbnails`
--

DROP TABLE IF EXISTS `Thumbnails`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `Thumbnails` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `type` int DEFAULT NULL,
  `modificationDate` datetime DEFAULT NULL,
  `orientationHint` int DEFAULT NULL,
  `data` longblob,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=278661 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `UniqueHashes`
--

DROP TABLE IF EXISTS `UniqueHashes`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `UniqueHashes` (
  `uniqueHash` varchar(128) DEFAULT NULL,
  `fileSize` bigint DEFAULT NULL,
  `thumbId` bigint DEFAULT NULL,
  UNIQUE KEY `uniqueHash` (`uniqueHash`,`fileSize`),
  KEY `id_uniqueHashes` (`thumbId`),
  CONSTRAINT `UniqueHashes_Thumbnails` FOREIGN KEY (`thumbId`) REFERENCES `Thumbnails` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `VideoMetadata`
--

DROP TABLE IF EXISTS `VideoMetadata`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `VideoMetadata` (
  `imageid` bigint NOT NULL,
  `aspectRatio` text CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci,
  `audioBitRate` text CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci,
  `audioChannelType` text CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci,
  `audioCompressor` text CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci,
  `duration` text CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci,
  `frameRate` text CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci,
  `exposureProgram` int DEFAULT NULL,
  `videoCodec` text CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci,
  PRIMARY KEY (`imageid`),
  CONSTRAINT `VideoMetadata_Images` FOREIGN KEY (`imageid`) REFERENCES `Images` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Dump completed on 2025-08-29 15:15:50
