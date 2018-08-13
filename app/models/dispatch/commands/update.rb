class Dispatch::Commands::Update < Command
  required_params :dispatch, :updates

  def perform
    report.report_events << dispatch_answered_event
    case report.status
    when Report::STATUS_NEW
      if updates[:status] == Dispatch::STATUS_ACCEPTED
        dispatch.update_attributes(updates)
        report.update_attributes(
          responder: dispatch.responder,
          status: Report::STATUS_ASSIGNED
          )
        report.report_events << dispatch_accepted_event
      elsif updates[:status] == Dispatch::STATUS_DISMISSED
        dispatch.update_attributes(updates)
        report.update_attributes(
          status: Report::STATUS_DISMISSED
        )
        report.report_events << dispatch_dismissed_event
      end
    when /#{Report::STATUS_ASSIGNED}|#{Report::STATUS_DISMISSED}/
      if updates[:status] =~ /#{Dispatch::STATUS_ACCEPTED}|#{Dispatch::STATUS_DISMISSED}/
        dispatch.update_attributes(status: "STALE")
        return update_fail(:status, :dispatch_stale)
      end
    end

    report.save
    dispatch
  end

  def report
    @report ||= dispatch.report
  end

  def dispatch_answered_event
    report.report_events.build(
      event_type: ReportEvent::RESPONDER_DISPATCH_ANSWERED,
      payload: {
        status: updates[:status],
        affiliate_name: dispatch.responder.user.affiliate.name,
        affiliate_id: dispatch.responder.user.affiliate.id,
        responder_user_name: dispatch.responder.user.name,
        responder_user_id: dispatch.responder.user.id,
        responder_user_phone: dispatch.responder.user.phone
      }
    )
  end

  def dispatch_accepted_event
    report.report_events.build(
      event_type: ReportEvent::RESPONDER_DISPATCHED,
      payload: {
        affiliate_name: dispatch.responder.user.affiliate.name,
        affiliate_id: dispatch.responder.user.affiliate.id,
        responder_user_name: dispatch.responder.user.name,
        responder_user_id: dispatch.responder.user.id,
        responder_user_phone: dispatch.responder.user.phone
      }
    )
  end

  def dispatch_dismissed_event
    report.report_events.build(
      event_type: ReportEvent::REPORT_DISMISSED,
      payload: {
        affiliate_name: dispatch.responder.user.affiliate.name,
        affiliate_id: dispatch.responder.user.affiliate.id,
        responder_user_name: dispatch.responder.user.name,
        responder_user_id: dispatch.responder.user.id,
        responder_user_phone: dispatch.responder.user.phone
      }
    )
  end

  def update_fail(field, reason)
    dispatch.errors.add(field, reason)
    dispatch
  end
end
