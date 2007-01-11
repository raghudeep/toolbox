% Samples elements of X so result uses at most maxmegs megabytes of memory.
% 
% If X is m+1 dimensional, say of size [d1 x d2 x...x dm x n], each [d1 x
% d2 x...x dm] element is treated as one observation, and X is treated as
% having n such observations.  The subsampling then occurs over the last
% dimension n.  Different types of arrays require different amounts of
% memory.  Each double requries 8 bytes of memory, hence an array with
% 1.024 million elements of type double requires 8MB memory.  Each uint8
% requires 1 byte, so the same size array would require 1MB.  Note that
% when saved to .mat files arrays may take up more or less memory (due to
% compression, etc.)
%
% Note, to see how much memory a variable x is using in memory, use:
%   s=whos('x'); mb=s.bytes/2^20
%
% USAGE
%  [X,keeplocs] = randomsample( X, maxmegs )
%
% INPUTS
%  X         - [d1 x ... x dm x n], treated as n [d1 x ... x dm] elements
%  maxmegs   - maximum number of megs Xsam is allowed to take up
% 
% OUTPUTS
%  Xsam      - [d1 x ... x dm x n'] (n'<=n) Xsam=X(:,..,:,keeplocs);
%  keeplocs  - vector of indicies kept from X;  
%
% EXAMPLE
%  % Xsam should have size: 1024xround(1024/10)
%  X = uint8(ones(2^10,2^10));
%  Xsam = randomsample( X, 1/10 );
%  % Xsam should have size: 100x10x~(1000/8) 
%  X = rand(100,10,1000);
%  Xsam = randomsample( X, 1 );
%
% DATESTAMP
%  10-Jan-2007  4:00pm

% Piotr's Image&Video Toolbox      Version 1.03   
% Written and maintained by Piotr Dollar    pdollar-at-cs.ucsd.edu 
% Please email me if you find bugs, or have suggestions or questions! 
 
function [X,keeplocs] = randomsample( X, maxmegs )
  siz = size( X );  nd = ndims(X);  
  inds={':'};  inds=inds(:,ones(1,nd-1));   
  n=siz(end);   m=prod(siz(1:end-1));

  % get the number of elements of X that fit per meg
  s=whos('X'); nbytes=s.bytes/numel(X);
  elspermeg = 2^20 / nbytes / m;

  % sample if necessary
  memused = n / elspermeg;
  if( memused > maxmegs )
   nkeep = max(1,round(maxmegs*elspermeg));
   keeplocs = randperm(n); 
   keeplocs = keeplocs(1:nkeep);
   X = X( inds{:}, keeplocs );
  end
