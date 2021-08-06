function col= getFASTTableColumn(tab, col_name)
col= tab.Table(:, find(strcmp(tab.Headers, col_name)));
