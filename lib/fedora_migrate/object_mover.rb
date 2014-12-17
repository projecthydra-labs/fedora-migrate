module FedoraMigrate
  class ObjectMover < Mover

    RIGHTS_DATASTREAM = "rightsMetadata".freeze

    def migrate
      prepare_target
      migrate_content_datastreams
      conversions.collect { |ds| convert_rdf_datastream(ds) }
      migrate_permissions
    end

    def post_initialize
      conversion_options
    end

    private

    def migrate_content_datastreams
      target.attached_files.keys.each do |ds|
        mover = FedoraMigrate::DatastreamMover.new(source.datastreams[ds.to_s], target.attached_files[ds.to_s])
        mover.migrate
      end
    end

    def convert_rdf_datastream ds
      if source.datastreams.keys.include?(ds)
        mover = FedoraMigrate::RDFDatastreamMover.new(source.datastreams[ds.to_s], target)
        mover.migrate
      end
    end

    def migrate_permissions
      if source.datastreams.keys.include?(RIGHTS_DATASTREAM) && target.respond_to?(:permissions)
        mover = FedoraMigrate::PermissionsMover.new(source.datastreams[RIGHTS_DATASTREAM], target)
        mover.migrate
      end
    end

    def prepare_target
      create_target_model if target.nil?
      Logger.info "using target object #{target.id}"
      save
    end

    def create_target_model
      afmodel = source.models.map { |m| m if m.match(/afmodel/) }.compact.first.split(/:/).last
      Logger.info "found #{afmodel} in source object #{source.pid}"
      @target = afmodel.constantize.new(id: source.pid.split(/:/).last)
    end

  end
  
end
