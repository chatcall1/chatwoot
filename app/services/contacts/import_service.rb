class Contacts::ImportService
  pattr_initialize [:account!, :user!, :file!, :label_ids, :inbox_id]

  def perform
    labels = account.labels.where(id: normalized_label_ids)
    raise ActiveRecord::RecordNotFound, 'One or more labels were not found' if labels.count != normalized_label_ids.count

    validate_inbox!

    ActiveRecord::Base.transaction do
      import = account.data_imports.create!(
        data_type: 'contacts',
        initiated_by: user, source_metadata: source_metadata(labels)
      )
      import.import_file.attach(file)
      import
    end
  end

  private

  def validate_inbox!
    return if campaign_inbox.blank? || campaign_inbox.whatsapp?

    raise ArgumentError, 'WhatsApp inbox required'
  end

  def campaign_inbox
    @campaign_inbox ||= account.inboxes.find(inbox_id) if inbox_id.present?
  end

  def source_metadata(labels)
    {
      campaign_label_titles: labels.pluck(:title), campaign_inbox_id: campaign_inbox&.id,
      process_immediately: normalized_label_ids.present? || campaign_inbox.present?
    }
  end

  def normalized_label_ids
    @normalized_label_ids ||= Array(label_ids).compact_blank.uniq
  end
end
