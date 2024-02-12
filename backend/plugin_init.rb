# Override for the uris until https://archivesspace.atlassian.net/browse/ANW-1843 is implemented

class EADSerializer < ASpaceExport::Serializer

  def serialize_aspace_uri(data, xml)
    # Do nothing
  end

end

class EAD3Serializer < EADSerializer

  def serialize_aspace_uri(data, xml)
    # Do nothing
  end

end
