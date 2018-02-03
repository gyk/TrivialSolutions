g = load('graph.txt');
if isempty(g)
	k = 1;
elseif bipartite(g, true)
	k = 2;
else
	k = 4;
end

fprintf('The graph is %d(+/-1)-colorable, \n', k);
