class IvlNotices::ConditionalEligibilityNoticeBuilder < IvlNotices::NoticeBuilder

  def initialize(hbx_enrollment_id)
    super(PdfTemplates::ConditionalEligibilityNotice, {
      template: "notices/ivl/9f_conditional_eligibility_confirmation_notification.html.erb"
    })
    @hbx_enrollment_id = hbx_enrollment_id
  end

  def build
    @hbx_enrollment = HbxEnrollment.find(@hbx_enrollment_id)
    @consumer = @hbx_enrollment.subscriber.person
    super
    @family = @consumer.primary_family
    hbx_enrollments = @family.try(:latest_household).try(:hbx_enrollments).active rescue []  
    append_enrollments(hbx_enrollments)
    append_individuals(hbx_enrollments)
  end
end