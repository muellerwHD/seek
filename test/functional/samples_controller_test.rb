require 'test_helper'

class SamplesControllerTest < ActionController::TestCase

  include AuthenticatedTestHelper
  include SharingFormTestHelper

  test 'index' do
    Factory(:sample,:policy=>Factory(:public_policy))
    get :index
    assert_response :success
  end

  test 'new' do
    login_as(Factory(:person))
    get :new
    assert_response :success
    assert assigns(:sample)
  end

  test 'show' do
    get :show, id: populated_patient_sample.id
    assert_response :success
  end

  test 'new with sample type id' do
    login_as(Factory(:person))
    type = Factory(:patient_sample_type)
    get :new, sample_type_id: type.id
    assert_response :success
    assert assigns(:sample)
    assert_equal type, assigns(:sample).sample_type
  end

  test 'create' do
    person = Factory(:person)
    login_as(person)
    type = Factory(:patient_sample_type)
    assert_difference('Sample.count') do
      post :create, sample: { sample_type_id: type.id, full_name: 'George Osborne', age: '22', weight: '22.1', postcode: 'M13 9PL' }
    end
    assert assigns(:sample)
    sample = assigns(:sample)
    assert_equal 'George Osborne', sample.title
    assert_equal 'George Osborne', sample.full_name
    assert_equal '22', sample.age
    assert_equal '22.1', sample.weight
    assert_equal 'M13 9PL', sample.postcode
    assert_equal person.user,sample.contributor
  end

  test 'edit' do
    login_as(Factory(:person))
    get :edit, id: populated_patient_sample.id
    assert_response :success
  end

  test 'update' do
    login_as(Factory(:person))
    sample = populated_patient_sample
    type_id = sample.sample_type.id

    assert_no_difference('Sample.count') do
      put :update, id: sample.id, sample: { full_name: 'Jesus Jones', age: '47', postcode: 'M13 9QL' }
    end

    assert assigns(:sample)
    assert_redirected_to assigns(:sample)
    updated_sample = assigns(:sample)
    updated_sample = Sample.find(updated_sample.id)
    assert_equal type_id, updated_sample.sample_type.id
    assert_equal 'Jesus Jones', updated_sample.title
    assert_equal 'Jesus Jones', updated_sample.full_name
    assert_equal '47', updated_sample.age
    assert_nil updated_sample.weight
    assert_equal 'M13 9QL', updated_sample.postcode
  end

  test 'associate with project on create' do
    person = Factory(:person_in_multiple_projects)
    login_as(person)
    type = Factory(:patient_sample_type)
    assert person.projects.count >= 3 #incase the factory changes
    project_ids = person.projects[0..1].collect(&:id)
    assert_difference('Sample.count') do
      post :create, sample: { sample_type_id: type.id, title: 'My Sample', full_name: 'George Osborne', age: '22', weight: '22.1', postcode: 'M13 9PL', project_ids:project_ids }
    end
    assert sample=assigns(:sample)
    assert_equal person.projects[0..1].sort,sample.projects.sort
  end

  test 'associate with project on update' do
    person = Factory(:person_in_multiple_projects)
    login_as(person)
    sample = populated_patient_sample
    assert_empty sample.projects
    assert person.projects.count >= 3 #incase the factory changes
    project_ids = person.projects[0..1].collect(&:id)

    put :update, id: sample.id, sample: { title: 'Updated Sample', full_name: 'Jesus Jones', age: '47', postcode: 'M13 9QL',project_ids:project_ids }

    assert sample=assigns(:sample)
    assert_equal person.projects[0..1].sort,sample.projects.sort

  end

  test 'contributor can view' do
    person = Factory(:person)
    login_as(person)
    sample = Factory(:sample, :policy=>Factory(:private_policy), :contributor=>person)
    get :show,:id=>sample.id
    assert_response :success
  end

  test 'non contributor cannot view' do
    person = Factory(:person)
    other_person = Factory(:person)
    login_as(other_person)
    sample = Factory(:sample, :policy=>Factory(:private_policy), :contributor=>person)
    get :show,:id=>sample.id
    assert_response :forbidden
  end

  test 'anonymous cannot view' do
    person = Factory(:person)
    sample = Factory(:sample, :policy=>Factory(:private_policy), :contributor=>person)
    get :show,:id=>sample.id
    assert_response :forbidden
  end

  test 'contributor can edit' do
    person = Factory(:person)
    login_as(person)
    sample = Factory(:sample, :policy=>Factory(:private_policy), :contributor=>person)
    get :edit,:id=>sample.id
    assert_response :success
  end

  test 'non contributor cannot edit' do
    person = Factory(:person)
    other_person = Factory(:person)
    login_as(other_person)
    sample = Factory(:sample, :policy=>Factory(:private_policy), :contributor=>person)
    get :edit,:id=>sample.id
    assert_redirected_to sample
    refute_nil flash[:error]
  end

  test 'anonymous cannot edit' do
    person = Factory(:person)
    sample = Factory(:sample, :policy=>Factory(:private_policy), :contributor=>person)
    get :edit,:id=>sample.id
    assert_redirected_to sample
    refute_nil flash[:error]
  end

  test 'create with sharing' do
    person = Factory(:person)
    login_as(person)
    type = Factory(:patient_sample_type)


    assert_difference('Sample.count') do
      post :create, sample: { sample_type_id: type.id, title: 'My Sample', full_name: 'George Osborne', age: '22', weight: '22.1', postcode: 'M13 9PL', project_ids:[] },:sharing=>valid_sharing
    end
    assert sample=assigns(:sample)
    assert_equal person.user,sample.contributor
    assert_equal Policy::ALL_USERS,sample.policy.sharing_scope
    assert sample.can_view?(Factory(:person).user)
  end

  test 'update with sharing' do
    person = Factory(:person)
    other_person = Factory(:person)
    login_as(person)
    sample = populated_patient_sample
    sample.contributor=person
    sample.policy=Factory(:private_policy)
    sample.save!
    sample.reload
    refute sample.can_view?(other_person.user)

    put :update, id: sample.id, sample: { title: 'Updated Sample', full_name: 'Jesus Jones', age: '47', postcode: 'M13 9QL',project_ids:[] },:sharing=>valid_sharing

    assert sample=assigns(:sample)
    assert_equal Policy::ALL_USERS,sample.policy.sharing_scope
    assert sample.can_view?(other_person.user)
  end

  test 'filter by sample_type route' do
    assert_routing "sample_types/7/samples",{controller:"samples",action:"index",sample_type_id:"7"}
  end

  test 'filter by sample type' do
    sample_type1=Factory(:simple_sample_type)
    sample_type2=Factory(:simple_sample_type)
    sample1=Factory(:sample,:sample_type=>sample_type1,:policy=>Factory(:public_policy),:title=>"SAMPLE 1")
    sample2=Factory(:sample,:sample_type=>sample_type2,:policy=>Factory(:public_policy),:title=>"SAMPLE 2")

    get :index,:sample_type_id=>sample_type1.id
    assert_response :success
    assert samples = assigns(:samples)
    assert_includes samples, sample1
    refute_includes samples, sample2
  end

  test 'extract from data file' do
    person = Factory(:person)
    login_as(person)

    Factory(:string_sample_attribute_type, title:'String')

    data_file = Factory :data_file, :content_blob => Factory(:sample_type_populated_template_content_blob), :policy=>Factory(:public_policy), :contributor=>person.user
    refute data_file.sample_template?
    assert_empty data_file.possible_sample_types

    sample_type = SampleType.new title:'from template'
    sample_type.content_blob = Factory(:sample_type_template_content_blob)
    sample_type.build_attributes_from_template
    #this is to force the full name to be 2 words, so that one row fails
    sample_type.sample_attributes.first.sample_attribute_type = Factory(:full_name_sample_attribute_type)
    sample_type.sample_attributes[1].sample_attribute_type = Factory(:datetime_sample_attribute_type)
    sample_type.save!

    assert_difference("Sample.count",3) do
      post :extract_from_data_file, :data_file_id=>data_file.id
    end

    assert (samples = assigns(:samples))
    assert assigns(:rejected_samples)
    assert_equal 3, samples.count
    assert_equal 1, assigns(:rejected_samples).count
    assert_equal "Bob",assigns(:rejected_samples).first.full_name

    samples.each do |sample|
      assert_equal data_file, sample.originating_data_file
    end

    data_file.reload

    assert_equal samples.sort, data_file.extracted_samples.sort


  end

  private

  def populated_patient_sample
    sample = Sample.new title: 'My Sample', policy:Factory(:public_policy), contributor:Factory(:person)
    sample.sample_type = Factory(:patient_sample_type)
    sample.title = 'My sample'
    sample.full_name = 'Fred Bloggs'
    sample.age = 22
    sample.save!
    sample
  end
end
