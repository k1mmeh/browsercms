class Cms::DynamicViewsController < Cms::BaseController
  
  layout 'cms/administration'
  check_permissions :administrate  

  before_filter :set_menu_section
  before_filter :load_view, :only => [:show, :edit, :update, :destroy]
  before_filter :install_missing_helpers, :only => [:edit, :update]
    
  helper_method :dynamic_view_type, :dynamic_view_instance_type
  
  def index
    # resync filesystem views in the database, with the filesystem
    dynamic_view_type.static_sister_class.detect_and_load_new_templates if dynamic_view_type.static_sister_class

    allowed_types = [dynamic_view_type, dynamic_view_type.static_sister_class].compact
    # TODO
    # Not ideal to include 'deleted = false' condition in this manner.  Necessary now due to the decision
    # to make the StaticView abstract class not implement soft delete, so neither can AbstractView. So
    # #paginate will NOT automatically call not_deleted named scope.
    # However, DynamicView types do implement soft delete, so we need to add the condition.
    conditions = ["type IN (#{allowed_types.map {|t| "?"}.join(',')}) AND deleted = ?"].concat(
      allowed_types.map {|t| t.to_s}.concat([false])
    )

    @views = AbstractView.paginate(:conditions => conditions, :page => params[:page], :order => "name")
  end
  
  def new
    @view = dynamic_view_type.new_with_defaults
  end
  
  def create
    @view = dynamic_view_type.new(params[dynamic_view_type.name.underscore])
    if @view.save
      flash[:notice] = "#{dynamic_view_type} '#{@view.name}' was created"
      redirect_to cms_index_path_for(dynamic_view_type.name.underscore.pluralize)
    else
      render :action => "new"
    end
  end
  
  def show
    redirect_to [:edit, :cms, @view]
  end
  
  def update
    if @view.update_attributes(params[dynamic_view_instance_type.name.underscore])
      flash[:notice] = "#{dynamic_view_instance_type} '#{@view.name}' was updated"
      redirect_to cms_index_path_for(dynamic_view_type.name.underscore.pluralize)
    else
      render :action => "edit"
    end
  end
  
  def destroy
    @view.destroy
    flash[:notice] = "#{dynamic_view_type} '#{@view.name}' was deleted"
    redirect_to cms_index_path_for(dynamic_view_type.name.underscore.pluralize)    
  end
  
  protected
    def dynamic_view_type
      @dynamic_view_type ||= begin
        type = request.request_uri.split('/')[2].classify.constantize
        raise "Invalid Type" unless type.ancestors.include?(DynamicView)
        type
      end
    end

    def dynamic_view_instance_type
      @view.class
    end
  
    def set_menu_section
      @menu_section = dynamic_view_type.name.underscore.pluralize
    end  
    
    def load_view
      @view = AbstractView.find(params[:id])
    end

    # If defined @view is StaticView, cms_<method_name>_path url helper needs to
    # alias the DynamicView sister class' url helper.
    # TODO Change to alias as the method does nothing
    # TODO Should be implemented in a Helper specific to this controller.  There
    # isn't one at present.
    def install_missing_helpers
      return true unless @view.is_a?(StaticView)

      method_name = ActionController::RecordIdentifier.singular_class_name(@view)
      method_name = "cms_#{method_name}_path"

      return true if ActionView::Base.instance_methods.include?(method_name)

      sister_method = "cms_#{ActionController::RecordIdentifier.singular_class_name(@view.class.dynamic_sister_class)}_path"
      ActionView::Base.class_eval <<-STRING_INPUT
def #{method_name}(*args)
  #{sister_method}(*args)
end
STRING_INPUT

      return true
    end
end