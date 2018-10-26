ArchivesSpaceOAIRecord.class_eval do

  def to_oai_ead
    raise OAI::FormatException.new unless @jsonmodel_record['jsonmodel_type'] == 'resource'

    opts = {
      :include_daos => true,
      :use_numbered_c_tags => false
    }
    RequestContext.open(:repo_id => @sequel_record.repo_id) do
      ead = ASpaceExport.model(:ead).from_resource(@jsonmodel_record, @sequel_record.tree(:all, mode = :sparse),opts )

      record = []
      ASpaceExport::stream(ead).each do |chunk|
        record << chunk
      end

      remove_xml_declaration(record.join(""))
    end
  end

end
