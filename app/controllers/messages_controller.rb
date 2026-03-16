# frozen_string_literal: true

class MessagesController < ApplicationController
  before_action :set_project
  before_action :set_other_party

  def index
    # Mark messages received by current user as read (and status → seen) when viewing thread
    @project.messages.unread_by(current_user).find_each(&:mark_read!)
    # Mark "new message" notifications for this thread as read
    current_user.notifications.unread
      .where(type: "Notification::NewMessage", subject_type: "Message", subject_id: @project.messages.select(:id))
      .update_all(read_at: Time.current)
    @messages = @project.messages
      .where(sender: [current_user, @other_party], receiver: [current_user, @other_party])
      .ordered
    @messages = @messages.search_body(params[:q]) if params[:q].present?
    @message = @project.messages.build(sender: current_user, receiver: @other_party)
  end

  def create
    @message = @project.messages.build(message_params)
    @message.sender = current_user
    @message.receiver = @other_party
    if @message.save
      redirect_to project_messages_path(@project), notice: "Message sent."
    else
      @messages = @project.messages
        .where(sender: [current_user, @other_party], receiver: [current_user, @other_party])
        .ordered
      render :index, status: :unprocessable_entity
    end
  end

  private

  def set_project
    @project = find_visible_project(params[:project_id])
    redirect_to root_path, alert: "Project not found." unless @project
  end

  def set_other_party
    @other_party = @project.student == current_user ? @project.student.supervisor : @project.student
    redirect_to root_path, alert: "Invalid conversation." unless @other_party
  end

  def acknowledge
    @message = @project.messages.find(params[:id])
    if @message.acknowledge!(by: current_user)
      redirect_to project_messages_path(@project), notice: "Message acknowledged."
    else
      redirect_to project_messages_path(@project), alert: "You cannot acknowledge this message."
    end
  end

  def message_params
    params.require(:message).permit(:body, attachments: [])
  end
end