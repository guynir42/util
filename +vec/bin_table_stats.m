function [Tnew, edges] = bin_table_stats(T, edges, varargin)
% Usage: [Tnew, edges] = bin_table_stats(T, edges, varargin)
% Bin the table T along "edges" and calculate some basic statistics for each
% bin (nanmean, nanmedianm nanstd). The results are added as new columns.
%
% The varargin is passed directly to bin_table(). 
% 

    if nargin==0, help('util.vec.bin_table_stats'); return; end

    T2 = util.vec.bin_table(T,edges, varargin{:});
    
    func_list = {'nanmean', 'nanmedian', 'nanstd'};
    
    N = length(func_list);
    
    Tnew = array2table(NaN(height(T2), 1+N*width(T2)));
    
    for ii = 1:width(T2)
        
        Tnew{:,1} = cellfun(@numel, T2{:,ii});
        Tnew.Properties.VariableNames{1} = 'N';
        
        for jj = 1:N
        
            idx = N*(ii-1)+jj + 1;
            Tnew{:,idx} = cellfun(str2func(func_list{jj}), T2{:,ii});
            Tnew.Properties.VariableNames{idx} = [T2.Properties.VariableNames{ii} '_' func_list{jj}];
        
        end
        
    end
    
end