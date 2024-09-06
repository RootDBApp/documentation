==========
JS helpers
==========

.. toctree::
 :numbered:

General
=======

----------
Appearance
----------

backgroundColors: string[]
--------------------------

Sympy return an array of a bunch of colors :

.. code-block:: javascript
   :linenos:

   const backgroundColors = [
      '#58595b',
      '#4dc9f6',
      '#f67019',
      '#f53794',
      '#537bc4',
      '#acc236',
      '#166a8f',
      '#00a950',
      '#8549ba',
      '#1abc9c',
      '#2ecc71',
      '#3498db',
      '#9b59b6',
      '#34495e',
      '#16a085',
      '#27ae60',
      '#2980b9',
      '#8e44ad',
      '#2c3e50',
      '#f1c40f',
      '#e67e22'
   ];


rdb.getTextColor = (): string
-----------------------------

Will return the value of the ``--text-color`` CSS variable from the current theme in-use.


rdb.getTextColorSecondary = (): string
--------------------------------------

Will return the value of the ``--text-color-secondary`` CSS variable from the current theme in-use.


rdb.getSurfaceBorder = (): string
---------------------------------

Will return the value of the ``'--surface-border`` CSS variable from the current theme in-use.


---------
Utilities
---------

rdb.getReportPathWithParams = (reportId: number, parameters: Array<{ key: string, value: string | number }>): string
--------------------------------------------------------------------------------------------------------------------

To use with ``navigate`` hook from React. It will generate a complete URL to the linked report, with parameters.

.. code-block:: javascript
   :linenos:
   :emphasize-lines: 5,6,7,8,9,10,11

   const options = {
      // ...
      onClick: (e) => {
         navigate(
            rdb.getReportPathWithParams(
               <linked_report_id>,
               [
                  {key: '<linked_report_input_parameter_variable_name_1>', value: getValueParam('<current_report_input_parameter_variable_name_a>')},
                  {key: '<linked_report_input_parameter_variable_name_2>', value: label}   // Value below mouse cursor.
               ]
            )
         );
      // ...
   };

rdb.sortArrayByKeyStringASC = (array: Array<any>, key: string): Array<any>
--------------------------------------------------------------------------

Allow you to order a table of object, using an object's attribute name as order key.

.. code-block:: javascript
   :linenos:
   :emphasize-lines: 26

   // Given this array of objects :
   const jsonResults = [
      {
         "x_label": "G",
         "dataset_value": 178
      },
      {
         "x_label": "PG",
         "dataset_value": 194
      },
      {
         "x_label": "R",
         "dataset_value": 195
      },
      {
         "x_label": "NC-17",
         "dataset_value": 210
      },
      {
         "x_label": "PG-13",
         "dataset_value": 223
      }
   ];

   // You can order elements this way :
   rdb.log( rdb.sortArrayByKeyStringASC(jsonResults, 'x_label') );

   // [
   //    {
   //       "x_label": "G",
   //       "dataset_value": 178
   //    },
   //    {
   //       "x_label": "NC-17",
   //       "dataset_value": 210
   //    },
   //    {
   //       "x_label": "PG",
   //       "dataset_value": 194
   //    },
   //    {
   //       "x_label": "PG-13",
   //       "dataset_value": 223
   //    },
   //    {
   //       "x_label": "R",
   //       "dataset_value": 195
   //    }
   // ]




rdb.log = (object: any): void
-----------------------------

Equivalent of the javascript ``console.log()``, but the output will appears in the debug tab. (``CTR+ALT+D`` to open it)

.. code-block:: javascript
   :linenos:
   :emphasize-lines: 1

   const labels = jsonResults.map(row => row.x_label);
   rdb.log(labels);

rdb.getCSV = (assetId: number): Promise<JSON>
---------------------------------------------

.. tip::

   Since RootDB v1.1.4

Async download of CSV asset. You'll get a parsed CSV as Json object as result.

.. code-block:: javascript
   :linenos:
   :emphasize-lines: 1

   rdb.getCSV(<assetId>).then((json_data) => {

     rdb.log(json_data);
   });

rdb.getJSON = (assetId: number): Promise<JSON>
----------------------------------------------

.. tip::

   Since RootDB v1.1.4

Async download of Json asset. You'll get a real Json object as result.

.. code-block:: javascript
   :linenos:
   :emphasize-lines: 1

   rdb.getJSON(<assetI>).then((json_data) => {

     rdb.log(json_data);
   });


Chart.js
========

-----------------------------------------------------
rdb.cjsOnHoverCursor = (event: any, chart: any): void
-----------------------------------------------------

To use with the ``onHover`` method from Chart.js ``options``, to transform the mouse cursor in a pointer when above clickable part of the chart.

.. code-block:: javascript
   :linenos:
   :emphasize-lines: 6

   const options = {
      // ...
      onClick: (e) => {
         // ...
      },
      onHover: (e) => rdb.cjsOnHoverCursor(e, chartXY)
   };


