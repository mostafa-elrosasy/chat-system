module PaginationConcern
    extend ActiveSupport::Concern
    DEFAULT_PAGE_SIZE = 10
	MAX_PAGE_SIZE = 100

    private
  
    def get_pagination_params
		page_number = params.fetch(:page_number, 1).to_i
		page_number = 1 if page_number < 1
        page_size = params.fetch(:page_size, DEFAULT_PAGE_SIZE).to_i
		page_size = DEFAULT_SEARCH_PAGE_SIZE if page_size <= 0 
		page_size = [page_size, MAX_PAGE_SIZE].min
        return page_number, page_size
    end

    def paginate(query)
        page_number, page_size = get_pagination_params()
        query.limit(page_size).offset((page_number - 1) * page_size)
    end
end