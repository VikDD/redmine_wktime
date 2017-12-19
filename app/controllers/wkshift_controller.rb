# ERPmine - ERP for service industry
# Copyright (C) 2011-2018  Adhi software pvt ltd
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
class WkshiftController < ApplicationController
  unloadable
	menu_item :wkattendance
	before_filter :require_login



	def index
		entries = WkShift.all	
		formPagination(entries)
	end
	
	def edit
		entries = nil
		set_filter_session
		departmentId =  session[controller_name][:department_id]
		locationId =  session[controller_name][:location_id]
		unless params[:shift_id].blank?
			@shiftObj = WkShift.find(params[:shift_id].to_i)			
			if (!departmentId.blank? && departmentId.to_i != 0 ) && !locationId.blank?
				entries = @shiftObj.shift_roles.where(:department_id => params[:department_id].to_i, :location_id => params[:location_id].to_i)
			elsif (!departmentId.blank? && departmentId.to_i != 0 ) && locationId.blank?
				entries = @shiftObj.shift_roles.where(:department_id => params[:department_id].to_i)
			elsif (departmentId.blank? || departmentId.to_i == 0 ) && !locationId.blank?
				entries = @shiftObj.shift_roles.where(:location_id => params[:location_id].to_i)
			else
				entries = @shiftObj.shift_roles
			end
			formPagination(entries)
		end
	end

	def update
		count = 0		
		errorMsg = ""
		arrId = WkShift.all.pluck(:id)
		for i in 0..params[:shift_id].length-1
			if params[:shift_id][i].blank?
				shiftEntries = WkShift.new
			else
				shiftEntries = WkShift.find(params[:shift_id][i].to_i)
			end
			shiftEntries.name = params[:name][i]
			shiftEntries.start_time = params[:start_time][i]
			shiftEntries.end_time = params[:end_time][i]
			shiftEntries.in_active = params[:inactive][i] unless params[:inactive].blank?
			if shiftEntries.save()
				arrId << shiftEntries.id
			else
				errorMsg =  timeEntries.errors.full_messages.join("<br>")
			end
		end
		WkShift.where.not(:id => arrId).delete_all()			
		
		redirect_to :controller => 'wkshift',:action => 'index' , :tab => 'wkshift'
		flash[:notice] = l(:notice_successful_update)
		flash[:error] = errorMsg unless errorMsg.blank?
	end
	
	def shiftRoleUpdate
		count = 0		
		errorMsg = ""
		unless params[:actual_ids].blank?
			arrId = params[:actual_ids].split(",").map { |s| s.to_i } 
		end
		for i in 0..params[:shift_role_id].length-1
			if params[:shift_role_id][i].blank?
				shiftRoleEntries = WkShiftRole.new
			else
				shiftRoleEntries = WkShiftRole.find(params[:shift_role_id][i].to_i)
				arrId.delete(params[:shift_role_id][i].to_i)
			end
			shiftRoleEntries.role_id = params[:role_id][i].to_i
			shiftRoleEntries.shift_id = params[:shift_id].to_i
			shiftRoleEntries.staff_count = params[:staff_count][i].to_i
			shiftRoleEntries.location_id = params[:location_id].to_i
			shiftRoleEntries.department_id = params[:department_id].to_i
			unless shiftRoleEntries.save()
				errorMsg =  timeEntries.errors.full_messages.join("<br>")
			end
		end
		WkShiftRole.where(:id => arrId).delete_all()
				
		redirect_to :controller => 'wkshift',:action => 'index' , :tab => 'wkshift'
		flash[:notice] = l(:notice_successful_update)
		flash[:error] = errorMsg unless errorMsg.blank?
	end
	
	def formPagination(entries)
		@entry_count = entries.count
        setLimitAndOffset()
		@shiftentry = entries.limit(@limit).offset(@offset)
	end
	
	def setLimitAndOffset		
		if api_request?
			@offset, @limit = api_offset_and_limit
			if !params[:limit].blank?
				@limit = params[:limit]
			end
			if !params[:offset].blank?
				@offset = params[:offset]
			end
		else
			@entry_pages = Paginator.new @entry_count, per_page_option, params['page']
			@limit = @entry_pages.per_page
			@offset = @entry_pages.offset
		end	
	end
	
	def set_filter_session
		if params[:searchlist].blank? && session[controller_name].nil?
			session[controller_name] = {:location_id => params[:location_id], :department_id => params[:department_id]}
		elsif params[:searchlist] == controller_name
			session[controller_name][:location_id] = params[:location_id]
			session[controller_name][:department_id] = params[:department_id]			
		end
		
	end

end
