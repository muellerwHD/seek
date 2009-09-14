class AdminController < ApplicationController
  before_filter :login_required
  before_filter :is_user_admin_auth

  use_google_charts

  def show
    respond_to do |format|
      format.html
    end
  end

  def tags
    @tags=Tag.find(:all)
  end

  def graphs

    width=300
    height=200

    data=created_at_data_for_model(Sop)
    dataset = GoogleChartDataset.new :data => data, :color => '0000DD'
    @sop_creation_graph = GoogleLineChart.new :width => width, :height => height, :title=>"Sop Creation"
    @sop_creation_graph.data = GoogleChartData.new :datasets => [dataset], :min=>0, :max=>data.max

    data=created_at_data_for_model(Model)
    dataset = GoogleChartDataset.new :data => data, :color => '0000DD'
    @model_creation_graph = GoogleLineChart.new :width => width, :height => height, :title=>"Model Creation"
    @model_creation_graph.data = GoogleChartData.new :datasets => [dataset], :min=>0, :max=>data.max

    data=created_at_data_for_model(DataFile)
    dataset = GoogleChartDataset.new :data => data, :color => '0000DD'
    @df_creation_graph = GoogleLineChart.new :width => width, :height => height, :title=>"Data File Creation"
    @df_creation_graph.data = GoogleChartData.new :datasets => [dataset], :min=>0, :max=>data.max

    data=created_at_data_for_model(User)
    dataset = GoogleChartDataset.new :data => data, :color => 'DD0000'
    @user_creation_graph = GoogleLineChart.new :width => width, :height => height, :title=>"User creation"
    @user_creation_graph.data = GoogleChartData.new :datasets => [dataset], :min=>0, :max=>data.max

  end

  def edit_tag
    if request.post?
      @tag=Tag.find(params[:id])
      @tag.taggings.select{|t| !t.taggable.nil?}.each do |tagging|
        context_sym=tagging.context.to_sym
        taggable=tagging.taggable
        current_tags=taggable.tag_list_on(context_sym).select{|tag| tag!=@tag.name}
        new_tag_list=current_tags.join(", ")

        replacement_tags=", "
        params[:tags_autocompleter_selected_ids].each do |selected_id|
          tag=Tag.find(selected_id)
          replacement_tags << tag.name << ","
        end unless params[:tags_autocompleter_selected_ids].nil?
        params[:tags_autocompleter_unrecognized_items].each do |item|
          replacement_tags << item << ","
        end unless params[:tags_autocompleter_unrecognized_items].nil?

        new_tag_list=new_tag_list << replacement_tags

        method_sym="#{tagging.context.singularize}_list=".to_sym

        taggable.send method_sym, new_tag_list

        taggable.save

      end

      @tag.destroy if Person.find_tagged_with(@tag.name).empty?      

      #FIXME: don't like this, but is a temp solution for handling lack of observer callback when removing a tag
      expire_fragment("tag_clouds")

      redirect_to :action=>:tags
    else
      @tag=Tag.find(params[:id])
      @all_tags_as_json=Tag.find(:all).collect{|t| {'id'=>t.id, 'name'=>t.name}}.to_json
      respond_to do |format|
        format.html
      end
    end

  end

  def delete_tag
    tag=Tag.find(params[:id])
    if request.post?
      tag.delete
      flash.now[:notice]="Tag #{tag.name} deleted"

    else
      flash.now[:error]="Must be a post"
    end

    #FIXME: don't like this, but is a temp solution for handling lack of observer callback when removing a tag
    expire_fragment("tag_clouds")

    redirect_to :action=>:tags
  end

  private

  def created_at_data_for_model model
    x={}
    start="1 Nov 2008"

    x[Date.parse(start).jd]=0
    x[Date.today.jd]=0

    model.find(:all, :order=>:created_at).each do |i|
      date=i.created_at.to_date
      day=date.jd
      x[day] ||= 0
      x[day]+=1
    end
    sorted_keys=x.keys.sort
    (sorted_keys.first..sorted_keys.last).collect{|i| x[i].nil? ? 0 : x[i]  }
  end



end
