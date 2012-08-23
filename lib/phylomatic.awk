function phylomatic(       ntaxatrees, taxa, newnode, i, nnodes, node, j, \
						   matched, k, x,thisnode, totbl, keep, divbl) 
{

  if (hasBL) ageToRoot();

  # GRAFT:

  # for each taxon in the `taxa` file
  # parse taxa
  gsub(/\n\n*$/,"",f["taxa"]);
  ntaxatrees = split(f["taxa"], taxa, "\n");
  newnode = 1;

  for (i = 1; i <= ntaxatrees; i++)
    {
	  # parse slashes
	  nnodes = split(taxa[i], nodetmp, "/");
	  # reverse the indices, so 1 is the terminal one
	  for (j = 1; j <= nnodes; j++) node[nnodes - j+1] =  nodetmp[j];

      #  climb through the levels of nesting from terminal to basal
      for (j = 1; j <= nnodes; j++)
        {
		  if (matched[i]) break;
		  for (k in taxon) # looping through all nodes in megatree
			               # that have taxa names
			{
			  #  compare with the taxon name at every node in the 
			  #  megatree

			  # if (taxon[k] == "shorea") print " shorea at t " i " vs " node[j] "\n"; 
			  if (node[j] == taxon[k])
				{
				  # print "found " taxon[k] " for t " i " j " j "/" nnodes "\n";
				  #  if matches, add to megatree:
				  
				  # terminal to terminal match:
				  if ((nDaughter[k] == 0) && (j==1))
					{
					  # flag the existing node and break (no graft, just prune)
					  keep[k] =1;
					  matched[i]=1;
					  nmatched++; 
					  break;
					}
				  # grafting needed
				  else 
					{
					  # deal with brach length adjustments
					  if (hasBL)
						{
						  if (nDaughter[k] == 0)
							{
							  # need to shift the BL of tip
							  ageNode(parent[k]);
							  divbl = age[parent[k]] / j;
							  if (!shiftedbl[k])
								{
								  bl[k] = divbl;
								  shiftedbl[k] = 1;
								}
							}
						  # internal match
						  else
							{
							  ageNode(k);
							  divbl = age[k] / (j-1);
							}
						}

					  x = k;

					  # starting with the node distal to the matched one
					  for (p = j-1; p >= 1; p--)
						{
						  thisnode = "pm" newnode;
						  if (hasBL) bl[thisnode] = divbl;
						  parent[thisnode] = x;
						  nDaughter[x]++;
						  taxon[thisnode] = node[p];
						  if (p == 1) keep[thisnode] = 1;
						  x = thisnode;
						  newnode++;
						}
					  matched[i]=1;
					  nmatched++; 
					  break;
					}
				}
			} 
		}
	}

  if(!nmatched) error("No taxa in common");

  # AND PRUNE:
  for (i in parent)
	{
	  # terminals only
	  if ((nDaughter[i] == 0) && keep[i])
		{
		  j = i;
		  # move up through tree
		  while ((parent[j] != "NULL") || (!parent[j]))
			{
			  # for possible cleaning (kpd = kept parent daughter)
			  kpd[parent[j] , j]=1;

			  j = parent[j];
			  keep[j]=1;
			}
		}
	  if (parent[j] == "NULL") keep[j]=1;
	}

  # now remove the elements not kept:
  # make sure only to reference arrays by looping in parent!

  for (i in parent)
	{
	  if (!keep[i]) delete parent[i];
	}

  # Finally, if phy is to be cleaned:
  if (tolower(f["clean"]) == "true")
	{
	  # find nkpd for each node
	  for (z1 in kpd) 
		{
		  split (z1 , z2, SUBSEP);
		  # print " z2[1] " z2[1] "  z2[2] " z2[2] "\n";
		  nkpd[z2[1]]++;
		}

	  for (i in parent)
		{
		  if (!nDaughter[i])
			{
			  # print "node " i ", parent " parent[i] ", nkpd " nkpd[i] ", tax " taxon[i] "\n";

			  j = i;
			  # move up through tree 
			  while ((parent[j] != "") && (parent[j] != "NULL"))
				{
				  # print "  considering parent of " j " -> " parent[j] " taxon " taxon[parent[j]] "\n";
				  x = parent[j];
				  xbl = 0;
				  # if the parent node is to be cleaned
				  while (nkpd[x] == 1)
					{
					  tobecleaned = x;
					  xbl += bl[tobecleaned];
					  x = parent[x];

					  # print "    deleted " tobecleaned " taxon " taxon[tobecleaned] "\n"
					  delete parent[tobecleaned];
					}
				  parent[j] = x;
				  bl[j] += xbl;
				  j = parent[j];
				}
			  # set new root
			  if (parent[j] == "NULL") root = j; 
			}
		}
	  # NULL was added to the index of parent, clear it:
	  delete parent["NULL"];
	}


  # Missing taxa
  if (nmatched < ntaxatrees)
	{
	  warning = "----\nNOTE: " ntaxatrees - nmatched " taxa not matched:\n";
	  for (i = 1; i <= ntaxatrees; i++)
		{
		  if (!matched[i])
			{
			  warning = warning taxa[i] "\n";
			}
		}
	}
}

function ageToRoot(     i, j)
{
  totalBL = 0;
  # assumes an ultrametric megatree
  for (i in parent)
	{
	  # find the first term
	  if (nDaughter[i] == 0)
		{
		  j = i;
		  # move up through tree
		  while ((parent[j] != "NULL") || (!parent[j]))
			{
			  totalBL = totalBL + bl[j];
			  j = parent[j];
			}
		  break;
		}
	}
}

function ageNode( innode,      j, sumBL)
{
  if (age[innode]) return;
  else
	{
	  j = innode;
	  # move up through tree
	  while ((parent[j] != "NULL") || (!parent[j]))
		{
		  sumBL = sumBL + bl[j];
		  j = parent[j];
		}
	}
  age[innode] = totalBL - sumBL;
  # print "Age of " innode " is " age[innode] "\n";
}