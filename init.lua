
local o = {}

-- Label the connected components of a binary image.
local function label(bw)
   -- Ensure that the input is binary.
   bw = bw:gt(0.5)

   -- Define our label matrix.
   local out = torch.zeros(bw:size()):int()

   -- Define our pixel processing queue
   local Q = {}

   -- Algorithm steps:
   --
   -- 1. Start from the first pixel in the image, set the current
   -- label to 1.
   local label = 1

   local is = bw:size(1)
   local js = bw:size(2)

   local nz = bw:nonzero()

   for ij=1,nz:size(1) do
      local i, j = nz[{ij,1}], nz[{ij,2}]

      -- 2. If the pixel is a foreground pixel and it has not already
      -- been labelled, give it the current label and add it as the first
      -- element in the queue, then go to 3. If it is a background pixel
      -- or it has already been labelled, repeat 2 for the next pixel in
      -- the image.
      --
      -- We don't need to check bw[{i,j}] == 1 because we are using
      -- only the non zero components
      if out[{i,j}] == 0 then
	 out[{i,j}] = label
	 Q[#Q+1] = {i, j}

	 -- 3. Pop out an element from the queue and look at its
	 -- neighbours. If a neighbour is a foreground pixel and is
	 -- not already labelled, give it the current label and add it
	 -- to the queue. Repeat 3 until there are no more elements in
	 -- the queue.
	 local q = table.remove(Q, 1)
	 while q do
	    local ii, jj = q[1], q[2]

	    -- Check up
	    if ii-1 > 1 and bw[{ii-1,jj}] == 1 and out[{ii-1,jj}] == 0 then
	       out[{ii-1,jj}] = label
	       Q[#Q+1] = {ii-1, jj}
	    end

	    -- Check down
	    if ii+1 < is and bw[{ii+1,jj}] == 1 and out[{ii+1,jj}] == 0 then
	       out[{ii+1,jj}] = label
	       Q[#Q+1] = {ii+1, jj}
	    end

	    -- Check left
	    if jj-1 > 1 and bw[{ii,jj-1}] == 1 and out[{ii,jj-1}] == 0 then
	       out[{ii,jj-1}] = label
	       Q[#Q+1] = {ii, jj-1}
	    end

	    -- Check right
	    if jj+1 < js and bw[{ii,jj+1}] == 1 and out[{ii,jj+1}] == 0 then
	       out[{ii,jj+1}] = label
	       Q[#Q+1] = {ii, jj+1}
	    end

	    q = table.remove(Q, 1)
	 end

	 -- 4. Go to 2 for the next pixel in the image and increment the
	 -- current label by 1.
	 label = label + 1

      end
   end

   return out
end

-- Find the centres of each connected compoent (as returned by the
-- label function).
local function centroids(cc)
   local m = cc:max()

   local cen = torch.FloatTensor(m, 2)

   for c=1,m do
      ind = torch.nonzero(cc:eq(c))
      cen[{c,{}}] = ind:float():mean(1)
   end

   return cen
end

return {
   label = label,
   centroids = centroids
}
