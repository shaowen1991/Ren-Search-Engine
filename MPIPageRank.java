import java.io.*;
//import java.security.KeyStore.Entry;
import java.util.*;
import mpi.MPI;
//import mpi.comm.intercomm;
import java.lang.Math;

//Code authors:  Shaowen Ren(shaoren)

public class MPIPageRank {
	
	private String inputFile = "";
    private String outputFile = "";
    private int iterations = 30;
    private double df = 0.85,delta = 0.001;
    
    private int size,rank;
    private int url_size,rank0size,rank1size;
    private int adjMatrix[][];
    private double rankValues[];
	
 	private void parseArgs(String[] args) {
		//mpjrun.sh -np 8 MPIPageRank <input_file_name> <output_file_name> <delta> <damping factor> <iterations>
    	inputFile = args[3];
    	outputFile = args[4];
    	if (args[5] != null) {
    		delta = Double.valueOf(args[5]);
    	}
    	if (args[6] != null) {
    		df = Double.valueOf(args[6]);
    	}
    	if (args[7] != null) {
    		iterations = Integer.valueOf(args[7]);
    	}
	}
	
    @SuppressWarnings("deprecation")
	private void loadInput_and_init() throws IOException {
    	
    	//input from file
    	File f = new File(inputFile);
    	InputStream is = new FileInputStream(f);
    	DataInputStream dis = new DataInputStream(is);
    	
		
		
    	ArrayList<String> tempMatrix = new ArrayList<String>();
    	String temp = null;
    	while ((temp = dis.readLine())!=null) {
			tempMatrix.add(temp);
		}
    	dis.close();
    	is.close();
    	
    	//initialize adjMatrix and rankValues
    	url_size = tempMatrix.size();
    	adjMatrix = new int[url_size][];
    	rankValues = new double[url_size];
    	int j = 0;
    	for (String temp1 : tempMatrix) {
    		String[] line = temp1.split(" ");
    		int index = Integer.valueOf(line[0]);
			adjMatrix[index] = new int[line.length -1];
			for (int i = 1; i < line.length; i++) {
				adjMatrix[index][i-1] = Integer.valueOf(line[i]);
			}
			rankValues[j] = 1.0 / url_size;
			j++;
		}
    	

        if (url_size % size == 0) {
        	//when the urls can be divided evenly
        	rank0size = url_size / size;
        	rank1size = rank0size;
        } else {
        	//when urls cannot be divided evenly, we are finding a most efficient way of allocating
            if (url_size < size) {
                rank0size = url_size;
                rank1size = 0;
                return;
            }
        	int temp1 = url_size;
        	int temp2 = url_size;
        	while (temp1 % size != 0) {
				temp1 ++;
			}
        	while (temp2 % size != 0) {
				temp2 --;
			}
        	if ((temp1 - url_size) <= (url_size - temp2)) {
				rank1size = temp1 / size;
			} else {
				rank1size = temp2 / size;
			}
        	rank0size = url_size - rank1size * (size - 1);
        }
    }
    
    private void printValues() throws IOException {
    	HashMap<Integer, Double> rankValues1 = new HashMap<Integer, Double>();
    	for (int i = 0; i < rankValues.length; i++) {
			rankValues1.put(i, rankValues[i]);
		}
    	
    	List<java.util.Map.Entry<Integer, Double>> rank = new ArrayList<java.util.Map.Entry<Integer, Double>>(rankValues1.entrySet());

        File f = new File(outputFile);
        OutputStream os = new FileOutputStream(f);
        DataOutputStream dos = new DataOutputStream(os);	
    	int i = 0;
    	for (java.util.Map.Entry<Integer, Double> entry : rank) {
    		
			if (i == 0) {
				dos.writeBytes("{" + "\"" + Integer.toString(entry.getKey()) + ".html\"=>" +Double.toString(entry.getValue()) + ",");
			}
			else if (i == rank.size()-1){ 
				dos.writeBytes("\"" + Integer.toString(entry.getKey()) + ".html\"=>" +Double.toString(entry.getValue()) + "}");
			}
			else{
				dos.writeBytes("\"" + Integer.toString(entry.getKey()) + ".html\"=>" +Double.toString(entry.getValue()) + ",");
			}
			i++;
    	}
    	dos.close();
    	os.close();
    }
    
    private int getstartpoint(int rank) {
    	if (rank == 0) {
			return 0;
		}
        else {
			return rank0size + (rank - 1) * rank1size;
		}
    }
	
	public void mpi(String[] args) throws IOException {
        //set start time inorder to calculate the running time
        long startTime = System.currentTimeMillis();

		//initial
		MPI.Init(args);
    	rank = MPI.COMM_WORLD.Rank();
        size = MPI.COMM_WORLD.Size();
        
		
        //parseArgs and save data
        parseArgs(args);
        
        //tempBuf to pass sizes
        int tempBuf[] = new int[3];
        if (rank == 0) {
        	//get all data from file
        	loadInput_and_init();
        	tempBuf[0] = url_size;
        	tempBuf[1] = rank0size;
        	tempBuf[2] = rank1size;
        }
        MPI.COMM_WORLD.Bcast(tempBuf, 0, 3, MPI.INT, 0);
        if (rank != 0) {
        	url_size = tempBuf[0];
            rank0size = tempBuf[1];
            rank1size = tempBuf[2];
            adjMatrix = new int[url_size][];
        	rankValues = new double[url_size];
        	for (int i = 0; i < rank0size; i++) {
				rankValues[i] = 1.0 / url_size;
			}
		}
        
        //now devide urls and send adjmatrix and initial pageranks
        for (int i = 1; i < size; i++) {
			for (int j = getstartpoint(i); j < getstartpoint(i + 1); j++) {
				if (rank == 0) {
					tempBuf[0] = adjMatrix[j].length;
					MPI.COMM_WORLD.Send(tempBuf, 0, 1, MPI.INT, i, 1);
					MPI.COMM_WORLD.Send(adjMatrix[j], 0, adjMatrix[j].length, MPI.INT, i, 1);
				} else {
					if (rank == i) {
						MPI.COMM_WORLD.Recv(tempBuf, 0, 1, MPI.INT, 0, 1);
						adjMatrix[j] = new int[tempBuf[0]];
						MPI.COMM_WORLD.Recv(adjMatrix[j], 0, adjMatrix[j].length, MPI.INT, 0, 1);
					}
					rankValues[j] = 1.0 / url_size;
				}
			}
		}
        
		for (int i = 0; i < iterations; i++) {
			double ranksum[] = new double[url_size];
			for (int j = getstartpoint(rank); j < getstartpoint(rank + 1); j++) {
				if (adjMatrix[j].length == 0) {
					for (int j2 = 0; j2 < url_size; j2++) {
						ranksum[j2] += rankValues[j] / url_size;
					}
				} else {
					for (int j2 = 0; j2 < adjMatrix[j].length; j2++) {
						ranksum[adjMatrix[j][j2]] += rankValues[j] / adjMatrix[j].length;
					}
				}
			}
			
			MPI.COMM_WORLD.Allreduce(ranksum, 0, ranksum, 0, url_size, MPI.DOUBLE, MPI.SUM);
			
			int[] flag = {0};
			if (rank == 0) {
				double tempdelta = 0;
				for (int j = 0; j < url_size; j++) {
					ranksum[j] = (1 - df) / url_size + df * ranksum[j];
					tempdelta += Math.abs(rankValues[j] - ranksum[j]);
					rankValues[j] = ranksum[j];
				}
				if (tempdelta < delta) {
					flag[0] ++;
				}
			}
			MPI.COMM_WORLD.Bcast(flag, 0, 1, MPI.INT, 0);
			MPI.COMM_WORLD.Bcast(rankValues, 0, url_size, MPI.DOUBLE, 0);
			if (flag[0]==1) {
				break;
			}
		}
		if (rank == 0) {
            long endTime   = System.currentTimeMillis();
            double totalTime = (endTime - startTime) * 0.001;
            
			printValues();
            
            //print out the running time here
			System.out.println("MPI Page Rank done!");
			System.out.println("Total processors invoked: " + size);
            System.out.println("The running time is: " + totalTime + " seconds");
		}
		MPI.Finalize();
		return;
	}
	
	public static void main(String[] args) throws IOException {
        
		MPIPageRank mpiPR = new MPIPageRank();
		mpiPR.mpi(args);
        
      
	}
}
