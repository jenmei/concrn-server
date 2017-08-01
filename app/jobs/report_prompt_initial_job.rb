class ReportPromptInitialJob < ApplicationJob
  def perform(report)
    report.update_attributes(next_handler: 'urgency')
    Message.create(
      report: report,
      to: report.reporter,
      text: "Thanks for letting your neighbors know you're concerned. Is anyone at risk of immediate harm? (Yes/No)"
    )
  end
end