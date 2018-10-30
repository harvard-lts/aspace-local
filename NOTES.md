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
2. We use external solr.  `AppConfig[:solr_url]` and `AppConfig[:pui_solr_host]` must be pointing to the external instance **SHARD** (**not** the ELB), and `AppConfig[:enable_solr] = false`

3. `AppConfig[:solr_backup_schedule] = "0 0 * * 1"`
4. Indexing:  
```ruby
AppConfig[:indexer_records_per_thread] = 25  
AppConfig[:indexer_thread_count] = 2  
AppConfig[:indexer_solr_timeout_seconds] = 600 
```
5. OAI:
```ruby
 AppConfig[:oai_ead_options] = {
          :include_daos => true,
          :use_numbered_c_tags => false
          }

```
6. Record inheritance:

```ruby
AppConfig[:record_inheritance] = {
  :archival_object => {
    :inherited_fields => [
                          {
                            :property => 'title',
                            :inherit_directly => true
                          },
                          {
                            :property => 'component_id',
                            :inherit_directly => false
                          },
                          {
                            :property => 'language',
                            :inherit_directly => true
                          },
                          {
                            :property => 'dates',
                            :inherit_directly => true
                          },
                          {
                            :property => 'extents',
                            :inherit_directly => true
                          },
                          {
                            :property => 'linked_agents',
                            :inherit_if => proc {|json| json.select {|j| j['role'] == 'creator'} },
                            :inherit_directly => false
                          },
                          {
                            :property => 'notes',
                            :inherit_if => proc {|json| json.select {|j| j['type'] == 'accessrestrict'} },
                            :inherit_directly => false
                          },
                          {
                            :property => 'notes',
                            :inherit_if => proc {|json| json.select {|j| j['type'] == 'scopecontent'} },
                            :inherit_directly => false
                          },
                          {
                            :property => 'notes',
                            :inherit_if => proc {|json| json.select {|j| j['type'] == 'langmaterial'} },
                            :inherit_directly => false
                          },
                          {
                            :property => 'notes',
                            :inherit_if => proc {|json| json.select {|j| j['type'] == 'physloc'} },
                            :inherit_directly => false
                          },
                         ]
  }
}
```

7. Changing the composite identifier delimiter:
```ruby
AppConfig[:record_inheritance][:archival_object][:composite_identifiers] = {
  :include_level => false,
  :identifier_delimiter => ', '
}
```
8. PUI configurations:  many PUI configuration keys are overridden directly in the **aspace-hvd-pui** plugin; here are some that aren't:
```ruby
AppConfig[:pui_enable_staff_link] = false # aspace-hvd-pui
AppConfig[:pui_feedback_link] = "http://nrs.harvard.edu/urn-3:hul.ois:archivesdiscovery"
AppConfig[:pui_help_link] = "https://guides.library.harvard.edu/hollisforarchivaldiscovery"
## PUI email settings (logs emails when disabled) aspace-hvd- 
AppConfig[:pui_email_enabled] = true  
AppConfig[:pui_email_delivery_method] = :sendmail 
AppConfig[:pui_email_sendmail_settings] = {  
  location: '/usr/sbin/sendmail',          
  arguments: '-i' 
 }   
AppConfig[:pui_email_perform_deliveries] = true  
AppConfig[:pui_email_raise_delivery_errors] = true    
AppConfig[:pui_perma] = "http://{whatever id.lib host is appropriate"
AppConfig[:pui_pdf_timeout] = 0
 AppConfig[:pui_stored_pdfs_url] = "https://{s3 path"
```
9. Ref id rule:
`AppConfig[:refid_rule] = "<%= eadid %>c<%= paddedseq %>"`
## Plugins:

We are using the following plugins:
* refid_rules
* [aspace-omniauth-cas](https://github.com/harvard-library/aspace-omniauth-cas)
* [aspace-import-excel](https://github.com/harvard-library/aspace-import-excel)
* [aspace-hvd-pui](https://github.com/harvard-library/aspace-hvd-pui)
* [aspace-ead-xform](https://github.com/harvard-library/aspace-ead-xform)
* [nla_accession_reports](https://github.com/harvard-library/nla_accession_reports)
* archivesspace_export_service #TODO: MV
* aspace-jsonmodel-from-format #TODO: MV
*  AND, IN QA ONLY AT THE MOMENT: #TODO: MV
   * request_list
   * harvard_request_list_customizations

