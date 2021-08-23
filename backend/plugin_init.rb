# Due to issues with the serializer, resources with refs in mixed content will fail because of a spurious
# application of the xlink namespace to attributes (specifically, @target)
#
# Once this PR is merged and a release with it adopted, this code can be removed
# https://github.com/archivesspace/archivesspace/pull/2353
class ReplacementSerializer < EADSerializer
  serializer_for :ead
  def add_xlink_prefix(content)
    %w{ actuate arcrole from href role show title to}.each do |xa|
      content.gsub!(/ #{xa}=/) {|match| " xlink:#{match.strip}"} if content =~ / #{xa}=/
    end
    content
  end
end

# Add this method to allow direct manipulation of serializers
module ASpaceExport
  def self.serializers
    @@serializers
  end
end

ASpaceExport.serializers.delete(EADSerializer)
# Note: serializers are searched in registration order,
# add to front in case EADSerializer is re-registered somehow
ASpaceExport.serializers.insert(0, ReplacementSerializer)
