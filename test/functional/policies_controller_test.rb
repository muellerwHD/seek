require 'test_helper'

class PoliciesControllerTest < ActionController::TestCase
  fixtures :all

  include AuthenticatedTestHelper

  def setup
    login_as(:datafile_owner)
  end

  test 'should show the preview permission when choosing public scope' do
    post :preview_permissions, sharing_scope: 4, access_type: 2, resource_name: 'data_file'

    assert_response :success
    assert_select 'p', text: "All visitors (including anonymous visitors with no login) can #{Policy.get_access_type_wording(2, 'data_file'.camelize.constantize.new).downcase}", count: 1
  end

  test 'should show the preview permission when choosing private scope' do
    post :preview_permissions, sharing_scope: 0, resource_name: 'data_file'

    assert_response :success
    assert_select 'p', text: /You keep this #{I18n.t('data_file')} private \(only visible to you\)/i, count: 1
  end

  test 'should show the preview permission when choosing network scope' do
    post :preview_permissions, sharing_scope: Policy::ALL_USERS, access_type: Policy::VISIBLE, resource_name: 'data_file'

    assert_response :success
    assert_select 'p', text: "All the #{I18n.t('project')} members within the network can #{Policy.get_access_type_wording(Policy::VISIBLE, 'data_file'.camelize.constantize.new).downcase}", count: 1
  end

  test 'should show the preview permission when custom the permissions for Person, Project and FavouriteGroup' do
    contributor_types = %w(Person FavouriteGroup Project)
    contributor_values = {}

    user = Factory(:user)
    login_as(user)

    # create a person and set access_type to Policy::MANAGING
    person =  Factory(:person_in_project)
    contributor_values['Person'] = { person.id => { 'access_type' => Policy::MANAGING } }

    # create a favourite group and members, set access_type to Policy::EDITING
    favorite_group = Factory(:favourite_group, user: user)
    contributor_values['FavouriteGroup'] = { favorite_group.id => { 'access_type' => -1 } }

    # create a project and members and set access_type to Policy::ACCESSIBLE
    project = Factory(:project)
    contributor_values['Project'] = { project.id => { 'access_type' => Policy::ACCESSIBLE } }

    post :preview_permissions, sharing_scope: 0, contributor_types: ActiveSupport::JSON.encode(contributor_types), contributor_values: ActiveSupport::JSON.encode(contributor_values), resource_name: 'data_file'

    assert_response :success
    assert_select 'h3', text: 'Fine-grained sharing permissions:', count: 1

    assert_select 'p', text: "#{person.name} can #{Policy.get_access_type_wording(Policy::MANAGING, 'data_file'.camelize.constantize.new.try(:is_downloadable?)).downcase}", count: 1
    assert_select 'p', text: "Members of Favourite group #{favorite_group.title} have #{Policy.get_access_type_wording(Policy::DETERMINED_BY_GROUP, 'data_file'.camelize.constantize.new.try(:is_downloadable?)).downcase}", count: 1
    assert_select 'p', text: "Members of #{I18n.t('project')} #{project.title} can #{Policy.get_access_type_wording(Policy::ACCESSIBLE, 'data_file'.camelize.constantize.new.try(:is_downloadable?)).downcase}", count: 1
  end

  test 'should show the correct manager(contributor) when updating a study' do
    study = Factory(:study)
    contributor = study.contributor
    post :preview_permissions, sharing_scope: Policy::EVERYONE, access_type: Policy::VISIBLE, is_new_file: 'false', contributor_id: contributor.user.id, resource_name: 'study'

    assert_select 'p', text: "#{contributor.person.name} can manage as an uploader", count: 1
  end

  test 'should show notice message when an item is requested to be published' do
    gatekeeper = Factory(:asset_gatekeeper)
    sop = Factory(:sop, project_ids: gatekeeper.projects.map(&:id))
    login_as(sop.contributor)
    post :preview_permissions, sharing_scope: Policy::EVERYONE, access_type: Policy::VISIBLE, is_new_file: 'false', resource_name: 'sop', resource_id: sop.id, project_ids: gatekeeper.projects.first.id.to_s
    assert_select 'p', text: "(An email will be sent to the Gatekeepers of the #{I18n.t('project').pluralize} associated with this #{I18n.t('sop')} to ask for publishing approval. This #{I18n.t('sop')} will not be published until one of the Gatekeepers has granted approval)", count: 1
  end

  test 'should show notice message when an item is requested to be published and the request was alread sent by this user' do
    gatekeeper = Factory(:asset_gatekeeper)
    sop = Factory(:sop, project_ids: gatekeeper.projects.map(&:id))
    login_as(sop.contributor)
    ResourcePublishLog.add_log ResourcePublishLog::WAITING_FOR_APPROVAL, sop
    post :preview_permissions, sharing_scope: Policy::EVERYONE, access_type: Policy::VISIBLE, is_new_file: 'false', resource_name: 'sop', resource_id: sop.id, project_ids: gatekeeper.projects.first.id.to_s

    assert_select 'p', text: "(You requested the publishing approval from the Gatekeepers of the #{I18n.t('project').pluralize} associated with this #{I18n.t('sop')}, and it is waiting for the decision. This #{I18n.t('sop')} will not be published until one of the Gatekeepers has granted approval)", count: 1
  end

  test 'should not show notice message when an item can be published right away' do
    post :preview_permissions, sharing_scope: Policy::EVERYONE, access_type: Policy::VISIBLE, is_new_file: 'true', resource_name: 'sop', project_ids: Factory(:project).id.to_s

    assert_select 'p', text: "(An email will be sent to the Gatekeepers of the  #{I18n.t('project').pluralize} associated with this #{I18n.t('sop')} to ask for publishing approval. This #{I18n.t('sop')} will not be published until one of the Gatekeepers has granted approval)", count: 0
  end

  test 'when creating an item, can not publish the item if associate to it the project which has gatekeeper' do
    gatekeeper = Factory(:asset_gatekeeper)
    a_person = Factory(:person)
    sample = Sample.new

    login_as(a_person.user)
    assert sample.can_manage?

    updated_can_publish_immediately = PoliciesController.new.updated_can_publish_immediately(sample, gatekeeper.projects.first.id.to_s)
    assert !updated_can_publish_immediately
  end

  test 'when creating an item, can publish the item if associate to it the project which has no gatekeeper' do
    a_person = Factory(:person)
    sample = Sample.new

    login_as(a_person.user)
    assert sample.can_manage?

    updated_can_publish_immediately = PoliciesController.new.updated_can_publish_immediately(sample, Factory(:project).id.to_s)
    assert updated_can_publish_immediately
  end

  test 'when updating an item, can not publish the item if associate to it the project which has gatekeeper' do
    as_not_virtualliver do
      gatekeeper = Factory(:asset_gatekeeper)
      a_person = Factory(:person)
      sample = Factory(:sample, policy: Factory(:policy))
      Factory(:permission, contributor: a_person, access_type: Policy::MANAGING, policy: sample.policy)
      sample.reload

      login_as(a_person.user)
      assert sample.can_manage?

      updated_can_publish_immediately = PoliciesController.new.updated_can_publish_immediately(sample, gatekeeper.projects.first.id.to_s)
      assert !updated_can_publish_immediately
    end
  end

  test 'when updating an item, can publish the item if dissociate to it the project which has gatekeeper' do
    as_not_virtualliver do
      gatekeeper = Factory(:asset_gatekeeper)
      a_person = Factory(:person)
      sample = Factory(:sample, policy: Factory(:policy), project_ids: gatekeeper.projects.collect(&:id))
      Factory(:permission, contributor: a_person, access_type: Policy::MANAGING, policy: sample.policy)
      sample.reload

      login_as(a_person.user)
      assert sample.can_manage?

      updated_can_publish_immediately = PoliciesController.new.updated_can_publish_immediately(sample, Factory(:project).id.to_s)
      assert updated_can_publish_immediately
    end
  end

  test 'can publish assay without study' do
    a_person = Factory(:person)
    assay = Assay.new

    login_as(a_person.user)
    assert assay.can_manage?

    updated_can_publish_immediately = PoliciesController.new.updated_can_publish_immediately(assay, '')
    assert updated_can_publish_immediately
  end

  test 'can not publish assay having project with gatekeeper' do
    as_not_virtualliver do
      gatekeeper = Factory(:asset_gatekeeper)
      a_person = Factory(:person)
      assay = Assay.new
      assay.study = Factory(:study, investigation: Factory(:investigation, project_ids: gatekeeper.projects.collect(&:id)))

      login_as(a_person.user)
      assert assay.can_manage?

      #FIXME: can't test controller this way properly as it doesnt setup the @request and session properly
      updated_can_publish_immediately = PoliciesController.new.updated_can_publish_immediately(assay, assay.study.id.to_s)
      assert !updated_can_publish_immediately
    end
  end

  test 'always can publish for the published item' do
    gatekeeper = Factory(:asset_gatekeeper)
    a_person = Factory(:person)
    login_as(gatekeeper.user)
    sample = Factory(:sample, contributor: gatekeeper.user, policy: Factory(:public_policy), project_ids: gatekeeper.projects.collect(&:id))
    Factory(:permission, contributor: a_person, access_type: Policy::MANAGING, policy: sample.policy)
    sample.reload

    login_as(a_person.user)
    assert sample.can_manage?

    updated_can_publish_immediately = PoliciesController.new.updated_can_publish_immediately(sample, gatekeeper.projects.first.id.to_s)
    assert updated_can_publish_immediately
  end

  test 'should show the preview permission for resource without projects' do
    post :preview_permissions, sharing_scope: 2, access_type: Policy::VISIBLE, project_access_type: Policy::ACCESSIBLE, project_ids: '0', resource_name: 'study'
    assert_response :success

    post :preview_permissions, sharing_scope: 2, access_type: Policy::VISIBLE, project_access_type: Policy::ACCESSIBLE, project_ids: '0', resource_name: 'assay'
    assert_response :success

    post :preview_permissions, sharing_scope: 2, access_type: Policy::VISIBLE, project_access_type: Policy::ACCESSIBLE, project_ids: '0', resource_name: 'sop'
    assert_response :success
  end

  test 'additional permissions and privilege text for preview permission' do
    # no additional text
    post :preview_permissions, sharing_scope: Policy::PRIVATE, access_type: Policy::NO_ACCESS, is_new_file: 'true', resource_name: 'assay'

    # with additional text for permissions
    project = Factory(:project)
    post :preview_permissions, sharing_scope: Policy::ALL_USERS, access_type: Policy::VISIBLE, resource_name: 'data_file',
                               project_ids: project.id, project_access_type: Policy::ACCESSIBLE

    # with additional text for privileged people
    asset_manager = Factory(:asset_housekeeper)
    post :preview_permissions, sharing_scope: Policy::PRIVATE, access_type: Policy::NO_ACCESS, resource_name: 'data_file',
                               project_ids: asset_manager.projects.first.id

    # with additional text for both permissions and privileged people
    asset_manager = Factory(:asset_housekeeper)
    post :preview_permissions, sharing_scope: Policy::ALL_USERS, access_type: Policy::VISIBLE, resource_name: 'data_file',
                               project_ids: asset_manager.projects.first.id, project_access_type: Policy::ACCESSIBLE
  end
end
