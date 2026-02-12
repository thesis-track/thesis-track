# frozen_string_literal: true

class DocumentVersionsController < ApplicationController
  before_action :set_project
  before_action :set_document
  before_action :set_document_version, only: %i[show destroy]

  def show
    if @document_version.file.attached?
      redirect_to rails_blob_path(@document_version.file), allow_other_host: true
    else
      redirect_to project_document_path(@project, @document), alert: "File not found."
    end
  end

  def create
    @document_version = @document.document_versions.build
    @document_version.file.attach(params[:file])
    if @document_version.save
      redirect_to project_document_path(@project, @document), notice: "New version uploaded."
    else
      redirect_to project_document_path(@project, @document), alert: @document_version.errors.full_messages.to_sentence
    end
  end

  def destroy
    @document_version.destroy
    redirect_to project_document_path(@project, @document), notice: "Version removed."
  end

  private

  def set_project
    @project = find_visible_project(params[:project_id])
    redirect_to root_path, alert: "Project not found." unless @project
  end

  def set_document
    @document = @project.documents.find(params[:document_id])
  end

  def set_document_version
    @document_version = @document.document_versions.find(params[:id])
  end
end