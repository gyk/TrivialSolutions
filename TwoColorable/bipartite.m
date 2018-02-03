function twoColorable = bipartite(graph, isSparse)
% Determines two-colorability of the given graph.
%   graph: n-by-2 array, each line of which represents an undirected edge 
%       connecting two nodes;
%   twoColorable: boolean;
	
	twoColorable = true;
	n = max(graph(:));
	color = zeros(n, 1);

	% builds adjacency matrix
	graphM = accumarray(graph, 1, [n n], [], 0, isSparse);
	graphM = graphM + graphM';

	q = make_queue(n);
	q.enqueue(graph(1));
	color(graph(1)) = 1;

	while ~q.empty()
		x = q.dequeue();
		c = color(x);
		adj = find(graphM(:, x));
		unvisited = color(adj) == 0;

		if any(color(adj(~unvisited)) == c)
			twoColorable = false;
			return;
		end

		color(adj(unvisited)) = 3 - c;
		q.enqueue(adj(unvisited));
	end
end

function q = make_queue(n)
%  A lame implementation of queue.
	queue = zeros(n, 1);
	head = 1;
	tail = 1;

	function [] = enqueue(xs)
		l = length(xs);
		queue(tail:tail+l-1) = xs;
		tail = tail + l;
	end

	function x = dequeue()
		x = queue(head);
		head = head + 1;
	end

	function b = empty()
		b = tail == head;
	end

	q.enqueue = @enqueue;
	q.dequeue = @dequeue;
	q.empty = @empty;
end
