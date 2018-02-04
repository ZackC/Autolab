# All modifications to the annotations are meant to be asynchronous and
# thus this contorller only exposes javascript interfaces.
#
# Only people acting as instructors or CA's should be able to do anything
# but view the annotations and since all of these mutate them, they are
# all restricted to those types.
class AnnotationsController < ApplicationController
  before_action :set_assessment
  before_action :set_submission
  before_action :set_annotation, except: [:create]
    rescue_from ActionView::MissingTemplate do |exception|
      redirect_to("/home/error_404")
  end

  respond_to :json

  # POST /:course/annotations.json
  action_auth_level :create, :course_assistant
  def create
    annotation = @submission.annotations.new(annotation_params)

    # If the annotation has a number in the score field
    if !annotation_params[:problem_id].blank?
      # Create a score object
      score = Score.new
      score.submission_id =  params[:submission_id]
      score.score = annotation_params[:value]
      score.problem_id = annotation_params[:problem_id]
      score.released = 0
      score.grader_id = @cud.id
      score.autograded = false
      score.save
      annotation.score_id = score.object_id
      annotation.save
      respond_with(@course, @assessment, @submission, annotation)
      return
    # Else:
    else
      # Save the annotation, return
      annotation.save
      respond_with(@course, @assessment, @submission, annotation)
      return
    end


    #annotation.save
    #respond_with(@course, @assessment, @submission, annotation)
  end

  # PUT /:course/annotations/1.json
  action_auth_level :update, :course_assistant
  def update
    @annotation.update(annotation_params)
    respond_with(@course, @assessment, @submission, @annotation) do |format|
      format.json { render json: @annotation }
    end
  end

  # DELETE /:course/annotations/1.json
  action_auth_level :destroy, :course_assistant
  def destroy
    @annotation.destroy
    head :no_content
  end

private

  def annotation_params
    params[:annotation].delete(:id)
    params[:annotation].delete(:created_at)
    params[:annotation].delete(:updated_at)
    params.require(:annotation).permit(:filename, :position, :line, :text, :submitted_by,
                                       :comment, :value, :problem_id,:submission_id, :coordinate)
  end

  def set_annotation
    @annotation = @submission.annotations.find(params[:id])
  end
end
