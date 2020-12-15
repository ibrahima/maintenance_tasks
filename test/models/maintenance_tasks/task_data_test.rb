# frozen_string_literal: true
require 'test_helper'

module MaintenanceTasks
  class TaskDataTest < ActiveSupport::TestCase
    test '.find returns a TaskData for an existing Task' do
      task_data = TaskData.find('Maintenance::UpdatePostsTask')
      assert_equal 'Maintenance::UpdatePostsTask', task_data.name
    end

    test '.find returns a TaskData for a deleted Task with a Run' do
      task_data = TaskData.find('Maintenance::DeletedTask')
      assert_equal 'Maintenance::DeletedTask', task_data.name
    end

    test '.find raises if the Task does not exist' do
      assert_raises Task::NotFoundError do
        TaskData.find('Maintenance::DoesNotExist')
      end
    end

    test '.available_tasks returns a list of Tasks as TaskData, ordered by active, new, then old' do
      Run.create!(task_name: 'Maintenance::UpdatePostsTask')
      Run.create!(
        task_name: 'Maintenance::ErrorTask',
        status: :errored,
        started_at: Time.now,
        ended_at: Time.now,
      )

      old_task = 'Maintenance::ErrorTask'
      new_task = 'MaintenanceTasks::TaskJobTest::TestTask'
      active_task = 'Maintenance::UpdatePostsTask'

      assert_equal [active_task, new_task, old_task],
        TaskData.available_tasks.map(&:name)
    end

    test '.available_tasks orders TaskData of the same category alphabetically' do
      Run.create!(task_name: 'Maintenance::UpdatePostsTask')
      Run.create!(task_name: 'Maintenance::ErrorTask')
      Run.create!(task_name: 'MaintenanceTasks::TaskJobTest::TestTask')

      expected = [
        'Maintenance::ErrorTask',
        'Maintenance::UpdatePostsTask',
        'MaintenanceTasks::TaskJobTest::TestTask',
      ]
      assert_equal expected, TaskData.available_tasks.map(&:name)
    end

    test '#new sets last_run if one is passed as an argument' do
      run = Run.create!(task_name: 'Maintenance::UpdatePostsTask')
      task_data = TaskData.new('Maintenance::UpdatePostsTask', run)

      assert_equal 'Maintenance::UpdatePostsTask', task_data.to_s
    end

    test '#code returns the code source of the Task' do
      task_data = TaskData.new('Maintenance::UpdatePostsTask')

      assert_equal 'class UpdatePostsTask < MaintenanceTasks::Task',
        task_data.code.each_line.grep(/UpdatePostsTask/).first.squish
    end

    test '#code returns nil if the Task does not exist' do
      task_data = TaskData.new('Maintenance::DoesNotExist')
      assert_nil task_data.code
    end

    test '#last_run returns the last Run associated with the Task' do
      Run.create!(
        task_name: 'Maintenance::UpdatePostsTask',
        status: :succeeded
      )
      latest = Run.create!(task_name: 'Maintenance::UpdatePostsTask')
      task_data = TaskData.new('Maintenance::UpdatePostsTask')

      assert_equal latest, task_data.last_run
    end

    test '#to_s returns the name of the Task' do
      task_data = TaskData.new('Maintenance::UpdatePostsTask')

      assert_equal 'Maintenance::UpdatePostsTask', task_data.to_s
    end

    test '#previous_runs returns all Runs for the Task except the first one' do
      run_1 = maintenance_tasks_runs(:update_posts_task)

      run_2 = Run.create!(
        task_name: 'Maintenance::UpdatePostsTask',
        status: :succeeded
      )

      Run.create!(task_name: 'Maintenance::UpdatePostsTask')

      task_data = TaskData.find('Maintenance::UpdatePostsTask')

      assert_equal 2, task_data.previous_runs.count
      assert_equal run_2, task_data.previous_runs.first
      assert_equal run_1, task_data.previous_runs.last
    end

    test '#previous_runs is empty when there are no Runs for the Task' do
      Run.destroy_all

      task_data = TaskData.find('Maintenance::UpdatePostsTask')

      assert_empty task_data.previous_runs
    end

    test '#deleted? returns true if the Task does not exist' do
      assert_predicate TaskData.new('Maintenance::DoesNotExist'), :deleted?
    end

    test '#deleted? returns false for an existing Task' do
      refute_predicate TaskData.new('Maintenance::UpdatePostsTask'), :deleted?
    end

    test '#status is new when Task does not have any Runs' do
      Run.destroy_all
      task_data = TaskData.find('Maintenance::UpdatePostsTask')
      assert_equal 'new', task_data.status
    end

    test '#status is the latest Run status' do
      Run.create!(task_name: 'Maintenance::UpdatePostsTask', status: :paused)
      task_data = TaskData.find('Maintenance::UpdatePostsTask')
      assert_equal 'paused', task_data.status
    end
  end
end