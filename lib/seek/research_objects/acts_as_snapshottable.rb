module Seek #:nodoc:
  module ResearchObjects
    module ActsAsSnapshottable #:nodoc:

      def self.included(mod)
        mod.extend(ClassMethods)
      end

      module ClassMethods

        def acts_as_snapshottable

          has_many :snapshots, as: :resource, foreign_key: :resource_id

          class_eval do
            extend Seek::ResearchObjects::ActsAsSnapshottable::SingletonMethods
          end

          include Seek::ResearchObjects::ActsAsSnapshottable::InstanceMethods

        end

        def is_snapshottable?
          include?(Seek::ResearchObjects::ActsAsSnapshottable::InstanceMethods)
        end

      end

      module SingletonMethods
      end

      module InstanceMethods

        def create_snapshot
          ro_file = Seek::ResearchObjects::Generator.new(self).generate
          snapshot = snapshots.create
          blob = ContentBlob.new({
                                     tmp_io_object: ro_file,
                                     content_type: Mime::Type.lookup_by_extension("ro").to_s,
                                     original_filename: "#{self.class.name.underscore}-#{self.id}-#{snapshot.snapshot_number}.ro.zip"
                                 })
          blob.asset = snapshot
          blob.save
          snapshot
        end

        def snapshot(number)
          snapshots.where(:snapshot_number => number).first
        end

      end

    end
  end
end

ActiveRecord::Base.class_eval do
  include Seek::ResearchObjects::ActsAsSnapshottable
end
