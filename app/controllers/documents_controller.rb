# frozen_string_literal: true

class DocumentsController < ApplicationController
  before_action :set_project
  before_action :set_document, only: %i[show]

  def index
    @documents = @project.documents.includes(:document_versions).order(:title)
  end

  def show
    @document_versions = @document.document_versions.order(version_number: :desc)
  end

  def new
    @document = @project.documents.build
  end

  def create
    @document = @project.documents.build(document_params)
    if @document.save
      redirect_to project_document_path(@project, @document), notice: "Document created. Upload a file to add version 1."
    else
      render :new, status: :unprocessable_entity
    end
  end

  private

  def set_project
    @project = find_visible_project(params[:project_id])
    redirect_to root_path, alert: "Project not found." unless @project
  end

  def set_document
    @document = @project.documents.find(params[:id])
  end

  def document_params
    params.require(:document).permit(:title)
  end
end