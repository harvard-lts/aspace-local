require 'nokogiri'
require 'securerandom'

class EADSerializer < ASpaceExport::Serializer
  serializer_for :ead

  def xml_errors(content)
    # there are message we want to ignore. annoying that java xml lib doesn't
    # use codes like libxml does...
    ignore = [ /Namespace prefix .* is not defined/, /The prefix .* is not bound./  ]
    ignore = Regexp.union(ignore)
    # the "wrap" is just to ensure that there is a psuedo root element to eliminate a "false" error
    #puts Nokogiri::XML("<wrap>#{content}</wrap>").errors
    Nokogiri::XML("<wrap>#{content}</wrap>").errors.reject { |e| e.message =~ ignore  }
  end


  def handle_linebreaks(content)
    # if there's already p tags, just leave as is
    return content if ( content.strip =~ /^<p(\s|\/|>)/ or content.strip.length < 1 )
    original_content = content
    blocks = content.split("\n\n").select { |b| !b.strip.empty? }
    if blocks.length > 1

      content = blocks.inject("") { |c,n| c << "<p>#{n.chomp}</p>"  }

      content = content.gsub("<p><note>","<note><p>").gsub("<p></note></p>","</note>").gsub("<p> </note></p>","</note>").gsub("</p></note></p>","</p></note>")


      content = content.gsub("<p><bioghist>","<bioghist><p>").gsub("</head>","</head><p>").gsub("<p></bioghist><bioghist>","</bioghist><bioghist><p>").gsub("<p></bioghist>","</bioghist><p>").gsub("<p><head>","<head>").gsub("</bioghist></p>","</p></bioghist>").gsub("<p><bioghist id","<bioghist id")
      content = content.gsub("<p><chronlist>","<chronlist>").gsub("<p><chronitem>","<chronitem>").gsub("</chronitem></p>","</chronitem>").gsub("</chronlist></p>","</chronlist>").gsub("<note>","<note><p>").gsub("</note>","</p></note>")
      #content = content.gsub("<p><scopecontent>","<scopecontent><p>").gsub("</scopecontent></p>","</scopecontent>").gsub("<p></scopecontent>","</scopecontent>")
      content = content.gsub("<p><blockquote>","<blockquote><p>").gsub("<p></blockquote>","</blockquote>").gsub("</blockquote></p>","</blockquote>").gsub("<p><date>","<date>")
      content = content.gsub("<p><arrangement>","<arrangement><p>").gsub("<p></arrangement>","</arrangement>").gsub("</arrangement></p>","</arrangement>")
      content = content.gsub("<p></daodesc>","</daodesc>").gsub("<daodesc>","<daodesc><p>")
      content = content.gsub("<p><p>","<p>").gsub("</p></p>","</p>")

    elsif content.start_with?("NOPARA:")
      content = content.split("NOPARA:")[1] 
      content = "#{content.strip}"
    else
      content = "<p>#{content.strip}</p>"
    end

    # first lets see if there are any &
    # note if there's a &somewordwithnospace , the error is EntityRef and wont
    # be fixed here...
    if xml_errors(content).any? { |e| e.message.include?("The entity name must immediately follow the '&' in the entity reference.") }
      content.gsub!("& ", "&amp; ")
    end

    # in some cases adding p tags can create invalid markup with mixed content
    # just return the original content if there's still problems
    xml_errors(content).any? ? original_content : content
    #xml_errors(content).any? ? content : content
  end

  def serialize_subnotes(subnotes, xml, fragments, include_p = true)
    subnotes.each do |sn|
      next if sn["publish"] === false && !@include_unpublished

      audatt = sn["publish"] === false ? {:audience => 'internal'} : {}

      title = sn['title']
      case sn['jsonmodel_type']
      when 'note_text'
        sanitize_mixed_content(sn['content'], xml, fragments, include_p )
      when 'note_chronology'
        xml.chronlist(audatt) {
          xml.head { sanitize_mixed_content(title, xml, fragments) } if title

          sn['items'].each do |item|
            xml.chronitem {
              if (val = item['event_date'])
                xml.date { sanitize_mixed_content( val, xml, fragments) }
              end
              if item['events'] && !item['events'].empty?
                xml.eventgrp {
                  item['events'].each do |event|
                    xml.event { sanitize_mixed_content(event, xml, fragments) }
                  end
                }
              end
            }
          end
        }
      when 'note_orderedlist'
        atts = {:type => 'ordered', :numeration => sn['enumeration']}.reject{|k,v| v.nil? || v.empty? || v == "null" }.merge(audatt)
        xml.list(atts) {
          xml.head { sanitize_mixed_content(title, xml, fragments) }  if title

          sn['items'].each do |item|
nopara = "NOPARA:" + item
#puts(item)
            xml.item {sanitize_mixed_content(nopara, xml, fragments, include_p)} 
            #xml.item {sanitize_mixed_content(item, xml, fragments)} 
          end
        }
      when 'note_definedlist'
        xml.list({:type => 'deflist'}.merge(audatt)) {
          xml.head { sanitize_mixed_content(title,xml, fragments) }  if title

          sn['items'].each do |item|
            xml.defitem {
              xml.label { sanitize_mixed_content(item['label'], xml, fragments) } if item['label']
              xml.item { sanitize_mixed_content(item['value'],xml, fragments )} if item['value']
            }
          end
        }
      end
    end
  end

  def serialize_eadheader(data, xml, fragments)
    eadheader_atts = {:findaidstatus => data.finding_aid_status,
                      :repositoryencoding => "iso15511",
                      :countryencoding => "iso3166-1",
                      :dateencoding => "iso8601",
                      :langencoding => "iso639-2b"}.reject{|k,v| v.nil? || v.empty? || v == "null"}

    xml.eadheader(eadheader_atts) {

      eadid_atts = {:countrycode => data.repo.country,
              :url => data.ead_location,
              :mainagencycode => data.mainagencycode}.reject{|k,v| v.nil? || v.empty? || v == "null" }

      xml.eadid(eadid_atts) {
        xml.text data.ead_id
      }

      xml.filedesc {

        xml.titlestmt {

          titleproper = ""
          titleproper += "#{data.finding_aid_title} " if data.finding_aid_title
          titleproper += "#{data.title}" if ( data.title && titleproper.empty? )
          titleproper += "<num>#{(0..3).map{|i| data.send("id_#{i}")}.compact.join('.')}</num>"
          xml.titleproper("type" => "filing") { sanitize_mixed_content(data.finding_aid_filing_title, xml, fragments)} unless data.finding_aid_filing_title.nil?
          xml.titleproper {  sanitize_mixed_content(titleproper, xml, fragments) }
          xml.subtitle {  sanitize_mixed_content(data.finding_aid_subtitle, xml, fragments) } unless data.finding_aid_subtitle.nil?
          xml.author { sanitize_mixed_content(data.finding_aid_author, xml, fragments) }  unless data.finding_aid_author.nil?
          xml.sponsor { sanitize_mixed_content( data.finding_aid_sponsor, xml, fragments) } unless data.finding_aid_sponsor.nil?

        }

        unless data.finding_aid_edition_statement.nil?
          xml.editionstmt {
            sanitize_mixed_content(data.finding_aid_edition_statement, xml, fragments, true )
          }
        end

        xml.publicationstmt {
          xml.publisher { sanitize_mixed_content(data.repo.name,xml, fragments) }

          if data.repo.image_url
            xml.p ( { "id" => "logostmt" } ) {
              xml.extref ({"xlink:href" => data.repo.image_url,
                          "xlink:actuate" => "onLoad",
                          "xlink:show" => "embed",
                          "xlink:type" => "simple"
                          })
                          }
          end
          if (data.finding_aid_date)
            xml.p {
                  val = data.finding_aid_date
                  xml.date {   sanitize_mixed_content( val, xml, fragments) }
                  }
          end

          unless data.addresslines.empty?
            xml.address {
              data.addresslines.each do |line|
                xml.addressline { sanitize_mixed_content( line, xml, fragments) }
              end
              if data.repo.url
                xml.addressline ( "URL: " ) {
                  xml.extptr ( {
                          "xlink:href" => data.repo.url,
                          "xlink:title" => data.repo.url,
                          "xlink:type" => "simple",
                          "xlink:show" => "new"
                          } )
                 }
              end
            }
          end
        }

        if (data.finding_aid_series_statement)
          val = data.finding_aid_series_statement
          xml.seriesstmt {
            sanitize_mixed_content(  val, xml, fragments, true )
          }
        end
        if ( data.finding_aid_note )
            val = data.finding_aid_note
            xml.notestmt { xml.note { sanitize_mixed_content(  val, xml, fragments, true )} }
        end

      }

      xml.profiledesc {
        creation = "This finding aid was produced using ArchivesSpace on <date>#{Time.now}</date>."
        xml.creation {  sanitize_mixed_content( creation, xml, fragments) }

        if (val = data.finding_aid_language)
          xml.langusage (fragments << val)
        end

        if (val = data.descrules)
          xml.descrules { sanitize_mixed_content(val, xml, fragments) }
        end
      }

      if data.revision_statements.length > 0
        xml.revisiondesc {
          data.revision_statements.each do |rs|
              #if rs['description'] && rs['description'].strip.start_with?('<')
              #  xml.text (fragments << rs['description'] )
              #else
                xml.change {
                  rev_date = rs['date'] ? rs['date'] : ""
                  xml.date (fragments <<  rev_date )
                  xml.item (fragments << rs['description']) if rs['description']
                }
              #end
          end
        }
      end
    }
  end

  def serialize_digital_object(digital_object, xml, fragments)
    return if digital_object["publish"] === false && !@include_unpublished
    return if digital_object["suppressed"] === true

    # ANW-285: Only serialize file versions that are published, unless include_unpublished flag is set 
    file_versions_to_display = digital_object['file_versions'].select {|fv| fv['publish'] == true || @include_unpublished }

    title = digital_object['title']
    date = digital_object['dates'][0] || {}

    atts = digital_object["publish"] === false ? {:audience => 'internal'} : {}

    content = ""
    content << title if title
    content << ": " if date['expression'] || date['begin']
    if date['expression']
      content << date['expression']
    elsif date['begin']
      content << date['begin']
      if date['end'] != date['begin']
        content << "-#{date['end']}"
      end
    end
    atts['xlink:title'] = digital_object['title'] if digital_object['title']


    if file_versions_to_display.empty?
      atts['xlink:type'] = 'simple'
      atts['xlink:href'] = digital_object['digital_object_id']
      atts['xlink:actuate'] = 'onRequest'
      atts['xlink:show'] = 'new'
      xml.dao(atts) {
        xml.daodesc{ sanitize_mixed_content(content, xml, fragments, true) } if content
      }
    elsif file_versions_to_display.length == 1
      file_version = file_versions_to_display.first

      atts['xlink:type'] = 'simple'
      atts['xlink:actuate'] = file_version['xlink_actuate_attribute'] || 'onRequest'
      atts['xlink:show'] = file_version['xlink_show_attribute'] || 'new'
      atts['xlink:role'] = file_version['use_statement'] if file_version['use_statement']
      atts['xlink:href'] = file_version['file_uri'] 
      atts['xlink:audience'] = get_audience_flag_for_file_version(file_version)
      xml.dao(atts) {
        xml.daodesc{ sanitize_mixed_content(content, xml, fragments, true) } if content
      }
    else
      xml.daogrp( atts.merge( { 'xlink:type' => 'extended'} ) ) {
        xml.daodesc{ sanitize_mixed_content(content, xml, fragments, true) } if content
        resatts = {}
	resatts['xlink:label'] = 'start'
	resatts['xlink:type'] = 'resource'
	xml.resource(resatts)
        file_versions_to_display.each do |file_version|
	  showAtt    = file_version['xlink_show_attribute']
	  actuateAtt = file_version['xlink_actuate_attribute']
          atts['xlink:type'] = 'locator'
          atts['xlink:href'] = file_version['file_uri'] 
          atts['xlink:role'] = file_version['use_statement'] if file_version['use_statement']
          atts['xlink:title'] = file_version['caption'] if file_version['caption']
          atts['xlink:audience'] = get_audience_flag_for_file_version(file_version)
          if showAtt == 'embed'
	    atts['xlink:label'] = 'thumb'
          elsif showAtt == 'new'
	    atts['xlink:label'] = 'reference'
	  end
          xml.daoloc(atts)
          arcatts = {}
	  arcatts['xlink:type'] = 'arc'
          arcatts['xlink:show'] = showAtt #file_version['xlink_show_attribute']
          arcatts['xlink:actuate'] = actuateAtt #file_version['xlink_actuate_attribute']
          if showAtt == 'embed'
	    arcatts['xlink:from'] = 'start'
	    arcatts['xlink:to'] = 'thumb'
          elsif showAtt == 'new'
	    arcatts['xlink:from'] = 'thumb'
	    arcatts['xlink:to'] = 'reference'
          end
          xml.arc(arcatts)
        end
      }
    end
  end
end
