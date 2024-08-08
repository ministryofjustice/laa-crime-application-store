class ChangeSentBackStatusString < ActiveRecord::Migration[7.1]
  def change
    Submission.where(application_state: 'further_info').update_all(application_state: 'sent_back')
  end
end
