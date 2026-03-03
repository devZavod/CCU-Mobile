import 'dart:ui';

import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(

      // 1. Barra superior
      appBar: AppBar(
        //title: const Text(),
        
        
        
        
        
      ),
      // 2. Cuerpo principal
      body: SingleChildScrollView(//El single hace posible el scroll
        child: Column(mainAxisAlignment: MainAxisAlignment.center,
          children: [

            Image.asset(
              'assets/images/logo.png',
                height: 100,  // ajusta el tamaño
      ),
            Center(
              child:Text("¡Saludo Estudiante!",textAlign: TextAlign.center,
              style:TextStyle(
                
                height: 5,
                fontSize: 24,
                fontWeight: FontWeight.bold
              )),
            ),
            
            SizedBox(
              
              width: double.infinity,
      
              child:ElevatedButton(
                onPressed:(){},
                style: ElevatedButton.styleFrom(
                  
                  padding: EdgeInsets.symmetric(vertical:30),
                
              ),
            
                  //Nota: Para modificar el tamaño del texto pones el
                  //estilo dentro del text
              child: Text(
                "Ver Horario",
                style: TextStyle(fontSize: 27),),
                
              )
            ),
            SizedBox(height: 16),//Esto es para separa cada botón


            SizedBox(
              
              width: double.infinity,
      
              child:ElevatedButton(
                onPressed:(){},
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical:30),
              
              ),
            
                  //Nota: Para modificar el tamaño del texto pones el
                  //estilo dentro del text
              child: Text(
                "Calcula tu Promedio",
                style: TextStyle(fontSize: 27),),

              )
            ),
            /////////////
            ///
            ///
            SizedBox(height: 16),
            ///
             SizedBox(
              
              width: double.infinity,
      
              child:ElevatedButton(
                onPressed:(){},
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical:30),
              
              ),
            
                  //Nota: Para modificar el tamaño del texto pones el
                  //estilo dentro del text
              child: Text(
                "Perfil",
                style: TextStyle(fontSize: 27),),

              )
            )
            
          
          ],
        ),
      ),

      
      floatingActionButton:FloatingActionButton(onPressed:(){},
      child:const Icon(Icons.add),
      )
    );
    
  }
  
}