package com.company;

import javax.xml.bind.JAXBException;
import java.io.*;
import java.util.*;
import java.util.regex.Pattern;

import org.dmg.pmml.FieldName;
import org.dmg.pmml.PMML;
import org.jpmml.evaluator.*;
import org.jpmml.model.PMMLUtil;
import org.jpmml.model.VisitorBattery;
import org.jpmml.model.visitors.AttributeInternerBattery;
import org.jpmml.model.visitors.LocatorNullifier;
import org.xml.sax.SAXException;
import com.google.common.collect.RangeSet;


/* Anemia max proba patient -[0.82224806] from python model
    data.put("ridageyr",   63.000000d);
    data.put("lbxsca",      9.100000d);
    data.put("lbxsch",    172.000000d);
    data.put("lbxscr",      2.580000d);
    data.put("lbxsgl",    116.000000d);
    data.put("lbxsir",     38.000000d);
    data.put("lbxsph",      5.100000d);
    data.put("diq010",      1.000000d);
    data.put("bpq020",      1.000000d);
    data.put("bpq080",      1.000000d);
    data.put("riagendr",    0.000000d);
    data.put("ridreth1",    4.000000d);
    data.put("huq071",      1.000000d);
    data.put("huq010",      5.000000d);
    data.put("mcq160l",     1.000000d);
    data.put("mcq160b",     0.000000d);
    data.put("mcq160c",     0.000000d);
    data.put("mcq160d",     0.000000d);
    data.put("mcq160e",     0.000000d);
    data.put("mcq160f",     0.000000d);
    data.put("gfr",    22.696143d);
*/

/*Hospitalization Max Risk Probability Patient - [0.82552651] from python

data.put("ridageyr",   76.000000d);
data.put("lbxhgb",      7.400000d);
data.put("lbxsca",      6.500000d);
data.put("lbxsch",    114.000000d);
data.put("lbxscr",      9.260000d);
data.put("lbxsgl",    210.000000d);
data.put("lbxsir",     22.000000d);
data.put("lbxsph",      7.200000d);
data.put("diq010",      1.000000d);
data.put("bpq020",      1.000000d);
data.put("bpq080",      0.000000d);
data.put("riagendr",    1.000000d);
data.put("ridreth1",    4.000000d);
data.put("huq010",      5.000000d);
data.put("mcq160l",     0.000000d);
data.put("mcq160b",     0.000000d);
data.put("mcq160c",     0.000000d);
data.put("mcq160d",     0.000000d);
data.put("mcq160e",     0.000000d);
data.put("mcq160f",     1.000000d);
data.put("gfr",         6.738282d);

*/

public class ExecPMML {

    public static void main(String[] args)throws IOException {
        String path = "D:\\Anemia\\src\\com\\company\\Anemia_rf_2.0.pmml";
//        String []continuousValues = new String[]{"lbxsir","gfr", "lbxscr", "lbxsca", "lbxsch", "lbxsgl", "lbxsph"}; //Anemia
        String []continuousValues = new String[]{"lbxscr", "lbxsgl", "lbxhgb"}; //Hospitalization
        PMML pmml = loadPMML(path);
        optimize(pmml);
        Evaluator evaluator = createEvaluator(pmml);
        evaluator.verify();
        int rangeSplits = 20;

        Map<String, Double[]> rangesDict = loadRangesFromFile();
        List<InputField> inputFields = evaluator.getInputFields();

        Map<String, Double> data =null;

        //csv headings
        System.out.println("Parameter Value,Risk Probability,Param");
        for(String contVar : continuousValues){
            Double[] range = rangesDict.get(contVar);
            double increment = (range[1] - range[0])/ rangeSplits;
            for(int i=0; i<rangeSplits;i++){
                //Make dataMap
                data = new HashMap<String, Double>(evaluator.getActiveFields().size());
                data.put("ridageyr",   76.000000d);
                data.put("lbxhgb",      7.400000d);
                data.put("lbxsca",      6.500000d);
                data.put("lbxsch",    114.000000d);
                data.put("lbxscr",      9.260000d);
                data.put("lbxsgl",    210.000000d);
                data.put("lbxsir",     22.000000d);
                data.put("lbxsph",      7.200000d);
                data.put("diq010",      1.000000d);
                data.put("bpq020",      1.000000d);
                data.put("bpq080",      0.000000d);
                data.put("riagendr",    1.000000d);
                data.put("ridreth1",    4.000000d);
                data.put("huq010",      5.000000d);
                data.put("mcq160l",     0.000000d);
                data.put("mcq160b",     0.000000d);
                data.put("mcq160c",     0.000000d);
                data.put("mcq160d",     0.000000d);
                data.put("mcq160e",     0.000000d);
                data.put("mcq160f",     1.000000d);
                data.put("gfr",         6.738282d);


                double inputVarValue = range[0]+(i*increment);
                data.put(contVar, inputVarValue);
                //Preprocess Input
                Map<FieldName, FieldValue> arguments = getInputArgs(evaluator, data);
                Map<FieldName, Double> results = (Map<FieldName, Double>)evaluator.evaluate(arguments);
                System.out.println(inputVarValue+","+getRiskProba(results)+","+contVar);
                data.clear();
            }
        }

    }//end main

    private static PMML loadPMML(String filePath){
        File file = new File(filePath);
        PMML pmml = null;
        try(InputStream is = new FileInputStream(file)){
            pmml = PMMLUtil.unmarshal(is);
        }catch(JAXBException | SAXException | IOException e){
            System.err.println("Error Occured ...\n");
            System.err.println(e.getMessage());
        }
        return pmml;
    }

    private static void optimize(PMML pmml){
        VisitorBattery visitorBattery = new VisitorBattery();
        visitorBattery.add(LocatorNullifier.class);
        visitorBattery.addAll(new AttributeInternerBattery());
        visitorBattery.applyTo(pmml);
    }

    private static Evaluator createEvaluator(PMML pmml){
        ModelEvaluatorFactory modelEvaluatorFactory = ModelEvaluatorFactory.newInstance();
        ValueFactoryFactory valueFactoryFactory = ReportingValueFactoryFactory.newInstance();
        modelEvaluatorFactory.setValueFactoryFactory(valueFactoryFactory);
        return modelEvaluatorFactory.newModelEvaluator(pmml);
    }

    private static void printValidRanges(Evaluator evaluator, List<InputField> inputFields){
        String formattedString;
        for(InputField inputField : inputFields) {
            switch (inputField.getOpType()) {
                case CONTINUOUS:
                    RangeSet<Double> argRanges = inputField.getContinuousDomain();
                     formattedString = String.format("%-10s : %-30s",inputField.getName(), argRanges.asRanges());
                    System.out.println(formattedString);
                    break;
                case CATEGORICAL:
                case ORDINAL:
                    List<?> argValues = inputField.getDiscreteDomain();
                    formattedString = String.format("%-10s : %-30s",inputField.getName(), argValues);
                    System.out.println(formattedString);
                    break;
                default:
                    break;
            }
        }
    }

    private static Map<FieldName, FieldValue> getInputArgs(Evaluator evaluator, Map<String, Double> data){
        List<InputField> inputFields = evaluator.getInputFields();
        Map<FieldName, FieldValue> arguments = new HashMap<>();
        for(InputField inputField : inputFields){
            FieldName inputFieldName = inputField.getName();
            FieldValue inputFieldValue = inputField.prepare(data.get(inputFieldName.getValue()));
            arguments.put(inputFieldName, inputFieldValue);
        }
        return arguments;
    }
    private static void prettyPrintDict(Map<FieldName, ?> dict){
        String formattedString;
        for(Map.Entry<FieldName, ?> entry: dict.entrySet()){
            formattedString = String.format("%-20s : %-20s", entry.getKey(), entry.getValue());
            System.out.println(formattedString);
        }
    }

    private static double getRiskProba(Map<FieldName,Double> results){
        Map.Entry<FieldName, Double> probaEntry = (Map.Entry<FieldName, Double>) results.entrySet().toArray()[2];
        return probaEntry.getValue();
    }

    private static TreeMap<String, Double[]> loadRangesFromFile()throws IOException{
        TreeMap<String, Double[]> map = new TreeMap<>();
        String rangeFilePath = "D:\\Anemia\\src\\com\\company\\rangeFile.txt";
        BufferedReader br = new BufferedReader(new FileReader(new File(rangeFilePath)));
        Pattern splitPattern = Pattern.compile("([:,])");
        String str = br.readLine();
        while(str !=  null){
            String splits[] = splitPattern.split(str);
            double d1 = Double.parseDouble(splits[1]);
            double d2 = Double.parseDouble(splits[2]);
            map.put(splits[0].trim(), new Double[]{d1,d2});
            str = br.readLine();
        }
        return map;
    }

    // OutputFields = probabilities
    // TargetFields = classLabels
}
