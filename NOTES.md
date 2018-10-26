# Notes

This file contains differences between the "Core" Archivesspace distribution and Havard's local instantiation.

## archivesspace.sh

To allow indexing to actually work:

```bash
ASPACE_JAVA_XMX="-Xmx24g"
```

## config.rb Notes

### Things to look for in upgrading:

1. Make sure that AppConfig[:omniauthCas] is defined.
2. We use external solr.  `AppConfig[:solr_url]` and `AppConfig[:pui_solr_host]` must be pointing to the external instance, and `AppConfig[:enable_solr] = false`

3. `AppConfig[:solr_backup_schedule] = "0 0 * * 1"`
4. Indexing:  
```ruby
 AppConfig[:indexer_records_per_thread] = 25  
AppConfig[:indexer_thread_count] = 2  
AppConfig[:indexer_solr_timeout_seconds] = 600 
```
5. Record ineritance:
```ruby
AppConfig[:record_inheritance][:archival_object][:composite_identifiers] = {
  :include_level => false,
  :identifier_delimiter => ', '
}
```
6. PUI configurations:
```ruby
AppConfig[:pui_enable_staff_link] = false # aspace-hvd-pui
AppConfig[:pui_feedback_link] = "http://nrs.harvard.edu/urn-3:hul.ois:archivesdiscovery"
AppConfig[:pui_help_link] = "https://guides.library.harvard.edu/hollisforarchivaldiscovery"
```
