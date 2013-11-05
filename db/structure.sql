CREATE TABLE "code_reviews" ("id" INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL, "description" text, "subject" varchar(255), "created" datetime, "modified" datetime, "cve" varchar(255), "issue" integer(8));
CREATE TABLE "comments" ("id" INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL, "author_email" varchar(255), "text" text, "draft" boolean, "lineno" integer, "date" datetime, "left" boolean, "patch_set_file_id" integer);
CREATE TABLE "cves" ("id" INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL, "cve" varchar(255));
CREATE TABLE "messages" ("id" INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL, "sender" varchar(255), "text" text, "approval" boolean, "disapproval" boolean, "date" datetime, "code_review_id" integer);
CREATE TABLE "patch_set_files" ("id" INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL, "filepath" varchar(255), "status" varchar(255), "num_chunks" integer, "no_base_file" boolean, "property_changes" boolean, "num_added" integer, "num_removed" integer, "is_binary" boolean, "patch_set_id" integer);
CREATE TABLE "patch_sets" ("id" INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL, "code_review_id" integer, "created" datetime, "num_comments" integer, "message" text, "modified" datetime, "patchset" integer(8));
CREATE TABLE "schema_migrations" ("version" varchar(255) NOT NULL);
CREATE UNIQUE INDEX "unique_schema_migrations" ON "schema_migrations" ("version");
INSERT INTO schema_migrations (version) VALUES ('20131016144416');

INSERT INTO schema_migrations (version) VALUES ('20131017173452');

INSERT INTO schema_migrations (version) VALUES ('20131017181525');

INSERT INTO schema_migrations (version) VALUES ('20131017182830');

INSERT INTO schema_migrations (version) VALUES ('20131017183919');

INSERT INTO schema_migrations (version) VALUES ('20131018135808');

INSERT INTO schema_migrations (version) VALUES ('20131018141506');

INSERT INTO schema_migrations (version) VALUES ('20131018142720');

INSERT INTO schema_migrations (version) VALUES ('20131018145059');

INSERT INTO schema_migrations (version) VALUES ('20131023155514');

INSERT INTO schema_migrations (version) VALUES ('20131023155813');

INSERT INTO schema_migrations (version) VALUES ('20131024215323');
